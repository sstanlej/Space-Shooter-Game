class_name Player extends CharacterBody2D

signal player_died
signal player_damage_taken

@export_group("Spawn & Intro Settings")
@export var game_pos_x: float = 30.0
@export var menu_pos_x: float = -240.0

@export_group("Ice Movement (Poślizg)")
@export var acceleration: float = 180.0     # Jak powoli statek się rozpędza (im mniej, tym większa inercja)
@export var friction: float = 85.0          # Siła hamowania (85 = długi, płynny ślizg na lodzie)
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

func _ready() -> void:
	if state_machine:
		state_machine.Initialize(self)

	if health_component:
		if not health_component.died.is_connected(_on_player_died):
			health_component.died.connect(_on_player_died)
		if health_component.has_signal("damage_taken") and not health_component.damage_taken.is_connected(_on_health_component_damage_taken):
			health_component.damage_taken.connect(_on_health_component_damage_taken)

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

	# 1. Płynne rozpędzanie vs Powolne ślizganie do zera
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# 2. Blokada wyjazdu poza ekran (zamiast zerowania direction)
	position.x = clampf(position.x, 12.0, 230.0)
	position.y = clampf(position.y, 10.0, 110.0)

func handle_visuals(delta: float) -> void:
	if not sprite:
		return

	# Przechył zależny od realnej prędkości w osi Y (działa również podczas ślizgu)
	var max_spd = max(get_movement_speed(), 1.0)
	var current_y_ratio = clampf(velocity.y / max_spd, -1.0, 1.0)
	var target_rotation = deg_to_rad(current_y_ratio * max_tilt_degrees)
	
	sprite.rotation = lerpf(sprite.rotation, target_rotation, tilt_speed * delta)

# --- ANIMACJE I PRZEJŚCIA ---

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 2.0)
	return tw

func set_is_attacking(value: bool) -> void:
	is_attacking = value

# --- SYGNAŁY ---

func _on_player_died() -> void:
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken() -> void:
	player_damage_taken.emit()

# --- GETTERY ---

func get_health_component() -> HealthComponent:
	return health_component

func get_attack_controller() -> AttackController:
	return attack_controller

func get_movement_speed() -> float:
	if stats_component and stats_component.has_method("get_final_movement_speed"):
		return stats_component.get_final_movement_speed()
	return 200.0