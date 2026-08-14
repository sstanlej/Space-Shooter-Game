class_name Player extends CharacterBody2D

signal player_died
signal player_damage_taken

@export_group("Spawn & Intro Settings")
@export var game_pos_x: float = 30.0
@export var menu_pos_x: float = -240.0

@export_group("Ice Movement (Poślizg)")
@export var acceleration: float = 180.0     # Jak powoli statek się rozpędza
@export var friction: float = 85.0          # Siła hamowania (długi ślizg)
@export var max_tilt_degrees: float = 8.0   # Przechył kadłuba
@export var tilt_speed: float = 6.0         # Płynność przechyłu

@export_group("Component References")
@onready var state_machine: PlayerStateMachine = get_node_or_null("StateMachine")
@onready var attack_controller: AttackController = get_node_or_null("AttackController")
@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var stats_component: PlayerStatsComponent = get_node_or_null("PlayerStatsComponent")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false

# Tweeny do efektów wizualnych
var flash_tween: Tween
var blink_tween: Tween

func _ready() -> void:
	if state_machine:
		state_machine.Initialize(self)

	# Podłączenie sygnałów z HealthComponent
	if health_component:
		if not health_component.died.is_connected(_on_player_died):
			health_component.died.connect(_on_player_died)
		if health_component.has_signal("damage_taken") and not health_component.damage_taken.is_connected(_on_health_component_damage_taken):
			health_component.damage_taken.connect(_on_health_component_damage_taken)
		if health_component.has_signal("invincibility_started") and not health_component.invincibility_started.is_connected(_on_invincibility_started):
			health_component.invincibility_started.connect(_on_invincibility_started)
		if health_component.has_signal("invincibility_ended") and not health_component.invincibility_ended.is_connected(_on_invincibility_ended):
			health_component.invincibility_ended.connect(_on_invincibility_ended)

	# Uruchomienie cząsteczek silnika / smug
	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

func _physics_process(delta: float) -> void:
	handle_input()
	handle_movement(delta)
	handle_visuals(delta)

# --- FIZYKA PORUSZANIA ---

func handle_input() -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		direction = Vector2.ZERO
		return

	var input_x = Input.get_action_strength("right") - Input.get_action_strength("left")
	var input_y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = Vector2(input_x, input_y).normalized()

func handle_movement(delta: float) -> void:
	var max_speed = get_movement_speed()
	var target_velocity = direction * max_speed

	# Płynne rozpędzanie vs Powolne ślizganie do zera
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# Blokada wyjazdu poza ekran
	position.x = clampf(position.x, 12.0, 230.0)
	position.y = clampf(position.y, 10.0, 110.0)

func handle_visuals(delta: float) -> void:
	if not sprite:
		return

	# Przechył zależny od realnej prędkości w osi Y
	var max_spd = max(get_movement_speed(), 1.0)
	var current_y_ratio = clampf(velocity.y / max_spd, -1.0, 1.0)
	var target_rotation = deg_to_rad(current_y_ratio * max_tilt_degrees)
	
	sprite.rotation = lerpf(sprite.rotation, target_rotation, tilt_speed * delta)

# --- EFEKTY WIZUALNE TRAFIEŃ I NIETYKALNOŚCI (JUICE) ---

func trigger_hit_flash() -> void:
	if not sprite:
		return

	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	# 1. Obsługa przez Shader (jeśli jest przypisany hit_flash.gdshader)
	if sprite.material and sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("active", true)
		flash_tween = create_tween()
		flash_tween.tween_interval(0.08)
		flash_tween.tween_callback(func():
			if sprite and sprite.material:
				sprite.material.set_shader_parameter("active", false)
		)
	# 2. Fallback: Błysk przez podbicie kanałów RGB modulacji
	else:
		var original_alpha = sprite.modulate.a
		sprite.modulate = Color(4.0, 4.0, 4.0, original_alpha)
		flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate:r", 1.0, 0.08)
		flash_tween.parallel().tween_property(sprite, "modulate:g", 1.0, 0.08)
		flash_tween.parallel().tween_property(sprite, "modulate:b", 1.0, 0.08)

func _on_invincibility_started(_duration: float = 0.0) -> void:
	if not sprite:
		return

	if blink_tween and blink_tween.is_running():
		blink_tween.kill()

	# Szybkie pulsowanie przezroczystością (0.2 <-> 1.0) co 0.08 sekundy
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.08)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.08)

func _on_invincibility_ended() -> void:
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if sprite:
		sprite.modulate.a = 1.0

# --- ANIMACJE I PRZEJŚCIA ---

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 2.0)
	return tw

func set_is_attacking(value: bool) -> void:
	is_attacking = value

# --- OBSŁUGA SYGNAŁÓW ZDROWIA ---

func _on_player_died() -> void:
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken(_amount: float = 0.0) -> void:
	player_damage_taken.emit()
	trigger_hit_flash()

# --- GETTERY ---

func get_health_component() -> HealthComponent:
	return health_component

func get_attack_controller() -> AttackController:
	return attack_controller

func get_movement_speed() -> float:
	if stats_component and stats_component.has_method("get_final_movement_speed"):
		return stats_component.get_final_movement_speed()
	return 200.0

func get_tilt_angle() -> float:
	return sprite.rotation if sprite else 0.0