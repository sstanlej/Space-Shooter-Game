class_name Player extends CharacterBody2D

signal player_died
signal player_damage_taken

@export_group("Spawn & Intro Settings")
@export var game_pos_x: float = 30.0
@export var menu_pos_x: float = -120.0

@export_group("Visuals")
@export var tilt_speed: float = 8.0

@export_group("Shield Visuals")
@export var shield_texture_full: Texture2D
@export var shield_texture_cracked: Texture2D
@onready var shield_sprite: Sprite2D = get_node_or_null("ShieldSprite")

var shield_tween: Tween

@export_group("Spectator Mode Settings")
@export var spectator_texture: Texture2D
@export var ghost_bullet_texture: Texture2D

@export_group("Component References")
@onready var attack_controller: AttackController = get_node_or_null("AttackController")
@onready var health_component: PlayerHealthComponent = get_node_or_null("HealthComponent")
@onready var deck_component: PlayerDeckComponent = get_node_or_null("PlayerDeckComponent")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var is_in_game: bool = false
var is_spectator: bool = false

var original_texture: Texture2D
var original_collision_layer: int = 0
var original_collision_mask: int = 0

var flash_tween: Tween
var blink_tween: Tween

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	position = Vector2(menu_pos_x, 60.0)
	is_in_game = false

	if sprite:
		original_texture = sprite.texture
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

	if health_component:
		if not health_component.died.is_connected(_on_player_died):
			health_component.died.connect(_on_player_died)
		if health_component.has_signal("damage_taken") and not health_component.damage_taken.is_connected(_on_health_component_damage_taken):
			health_component.damage_taken.connect(_on_health_component_damage_taken)
		if health_component.has_signal("invincibility_started") and not health_component.invincibility_started.is_connected(_on_invincibility_started):
			health_component.invincibility_started.connect(_on_invincibility_started)
		if health_component.has_signal("invincibility_ended") and not health_component.invincibility_ended.is_connected(_on_invincibility_ended):
			health_component.invincibility_ended.connect(_on_invincibility_ended)
		if not health_component.shield_hit.is_connected(_on_shield_hit):
			health_component.shield_hit.connect(_on_shield_hit)
		if not health_component.shield_broken.is_connected(_on_shield_broken):
			health_component.shield_broken.connect(_on_shield_broken)

	if deck_component:
		if not deck_component.deck_updated.is_connected(_sync_shield_from_deck):
			deck_component.deck_updated.connect(_sync_shield_from_deck)
		if not health_component.shield_hit.is_connected(deck_component.sync_shield_from_health):
			health_component.shield_hit.connect(deck_component.sync_shield_from_health)

	_sync_shield_from_deck()

	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

func _physics_process(delta: float) -> void:
	handle_input()
	handle_movement(delta)
	handle_visuals(delta)

# --- FIZYKA I STEROWANIE ---

func handle_input() -> void:
	if not is_in_game or Input.is_key_pressed(KEY_SHIFT):
		direction = Vector2.ZERO
		is_attacking = false
		return

	var input_x = Input.get_action_strength("right") - Input.get_action_strength("left")
	var input_y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = Vector2(input_x, input_y).normalized()

	# Bezpośrednie sterowanie ogniem bez maszyny stanów:
	is_attacking = Input.is_action_pressed("attack")

func handle_movement(delta: float) -> void:
	var max_speed = get_movement_speed()

	if is_spectator:
		velocity = direction * max_speed
		move_and_slide()
		if is_in_game:
			position.x = clampf(position.x, 12.0, 230.0)
			position.y = clampf(position.y, 10.0, 110.0)
		return

	var target_velocity = direction * max_speed
	var accel = deck_component.get_dynamic_acceleration() if deck_component else 950.0
	var friction = deck_component.get_dynamic_friction() if deck_component else 750.0

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	if is_in_game:
		position.x = clampf(position.x, 12.0, 230.0)
		position.y = clampf(position.y, 10.0, 110.0)

func handle_visuals(delta: float) -> void:
	if not sprite:
		return

	var current_max_spd = max(get_movement_speed(), 1.0)
	var dynamic_max_tilt = deck_component.get_dynamic_max_tilt() if deck_component else 8.0

	var current_y_ratio = clampf(velocity.y / current_max_spd, -1.0, 1.0)
	var target_rotation = deg_to_rad(current_y_ratio * dynamic_max_tilt)
	sprite.rotation = lerpf(sprite.rotation, target_rotation, tilt_speed * delta)

# --- TRYB SPECTATORA ---

func toggle_spectator_mode() -> bool:
	set_spectator_mode(!is_spectator)
	return is_spectator

func set_spectator_mode(enabled: bool) -> void:
	is_spectator = enabled
	velocity = Vector2.ZERO

	collision_layer = 0 if is_spectator else original_collision_layer
	collision_mask = 0 if is_spectator else original_collision_mask
	set_hurtboxes_enabled(!is_spectator)

	if health_component:
		health_component.is_invincible = is_spectator

	if sprite:
		if is_spectator:
			if spectator_texture:
				sprite.texture = spectator_texture
				sprite.modulate = Color.WHITE
			else:
				sprite.modulate = Color(1.0, 1.0, 1.0, 0.4)
		else:
			sprite.texture = original_texture
			sprite.modulate = Color.WHITE

	if attack_controller:
		attack_controller.set_ghost_mode(is_spectator, ghost_bullet_texture)

func set_hurtboxes_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", enabled)
			child.set_deferred("monitorable", enabled)

# --- PRZEJŚCIA I WIZUALIA ---

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 1.2)
	tw.tween_callback(func(): is_in_game = true)
	return tw

func move_to_menu_view() -> void:
	is_in_game = false
	velocity = Vector2.ZERO
	position = Vector2(menu_pos_x, 60.0)

func trigger_hit_flash() -> void:
	if not sprite or is_spectator:
		return

	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	if sprite.material and sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("active", true)
		flash_tween = create_tween()
		flash_tween.tween_interval(0.08)
		flash_tween.tween_callback(func():
			if sprite and sprite.material:
				sprite.material.set_shader_parameter("active", false)
		)
	else:
		var original_alpha = sprite.modulate.a
		sprite.modulate = Color(4.0, 4.0, 4.0, original_alpha)
		flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate:r", 1.0, 0.08)
		flash_tween.parallel().tween_property(sprite, "modulate:g", 1.0, 0.08)
		flash_tween.parallel().tween_property(sprite, "modulate:b", 1.0, 0.08)

func _on_invincibility_started(_duration: float = 0.0) -> void:
	if not sprite or is_spectator:
		return

	if blink_tween and blink_tween.is_running():
		blink_tween.kill()

	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.08)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.08)

func _on_invincibility_ended() -> void:
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if sprite and not is_spectator:
		sprite.modulate.a = 1.0

# --- OBSŁUGA WIZUALNA TARCZY ---

func _sync_shield_from_deck() -> void:
	if not deck_component:
		return
	update_shield_display(deck_component.shield_charges)

func update_shield_display(charges: int) -> void:
	if not shield_sprite:
		return

	if charges <= 0:
		shield_sprite.hide()
		return

	shield_sprite.show()
	if charges == 1 and shield_texture_cracked:
		shield_sprite.texture = shield_texture_cracked
	elif shield_texture_full:
		shield_sprite.texture = shield_texture_full

func _on_shield_hit(remaining_charges: int) -> void:
	update_shield_display(remaining_charges)
	trigger_shield_impact_effect()

func _on_shield_broken() -> void:
	update_shield_display(0)
	trigger_shield_broken_effect()

func trigger_shield_impact_effect() -> void:
	if not shield_sprite or not shield_sprite.visible:
		return

	if shield_tween and shield_tween.is_running():
		shield_tween.kill()

	shield_tween = create_tween()
	shield_sprite.scale = Vector2(1.3, 1.3)
	shield_sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	
	shield_tween.set_parallel(true)
	shield_tween.tween_property(shield_sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shield_tween.tween_property(shield_sprite, "modulate", Color.WHITE, 0.2)

func trigger_shield_broken_effect() -> void:
	if not shield_sprite:
		return
	shield_sprite.show()
	var break_tween = create_tween().set_parallel(true)
	break_tween.tween_property(shield_sprite, "scale", Vector2(1.5, 1.5), 0.15)
	break_tween.tween_property(shield_sprite, "modulate:a", 0.0, 0.15)
	break_tween.chain().tween_callback(func():
		shield_sprite.hide()
		shield_sprite.scale = Vector2.ONE
		shield_sprite.modulate = Color.WHITE
	)

# --- SYGNAŁY I GETTERY ---

func set_is_attacking(value: bool) -> void:
	is_attacking = value

func _on_player_died() -> void:
	if is_spectator:
		return
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken(_amount: int = 0) -> void:
	if is_spectator:
		return
	player_damage_taken.emit()
	trigger_hit_flash()

func get_health_component() -> HealthComponent:
	return health_component

func get_attack_controller() -> AttackController:
	return attack_controller

func get_deck_component() -> PlayerDeckComponent:
	return deck_component

func get_movement_speed() -> float:
	if deck_component:
		return deck_component.get_final_movement_speed()
	return 200.0

func get_tilt_angle() -> float:
	return sprite.rotation if sprite else 0.0