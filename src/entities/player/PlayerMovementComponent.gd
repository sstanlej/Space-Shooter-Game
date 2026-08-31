class_name PlayerMovementComponent extends Node

@export_group("Ice Physics & Visual Tuning")
@export var base_acceleration: float = 950.0
@export var base_friction: float = 750.0
@export var base_tilt_degrees: float = 8.0
@export var max_tilt_cap_degrees: float = 20.0
@export var tilt_speed: float = 8.0

@export_group("Screen Boundaries")
@export var min_x: float = 12.0
@export var max_x: float = 230.0
@export var min_y: float = 10.0
@export var max_y: float = 110.0

var player: Player
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	player = get_parent() as Player

func process_movement(delta: float) -> void:
	if not player:
		return

	handle_input()
	apply_movement(delta)
	apply_visual_tilt(delta)

func handle_input() -> void:
	if not player.is_in_game or Input.is_key_pressed(KEY_SHIFT):
		direction = Vector2.ZERO
		return

	var input_x = Input.get_action_strength("right") - Input.get_action_strength("left")
	var input_y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = Vector2(input_x, input_y).normalized()

func apply_movement(delta: float) -> void:
	var max_speed = get_movement_speed()

	if player.is_spectator:
		player.velocity = direction * max_speed
		player.move_and_slide()
		clamp_position()
		return

	var target_velocity = direction * max_speed
	var accel = get_dynamic_acceleration()
	var friction = get_dynamic_friction()

	if direction != Vector2.ZERO:
		player.velocity = player.velocity.move_toward(target_velocity, accel * delta)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)

	player.move_and_slide()
	clamp_position()

func clamp_position() -> void:
	if player.is_in_game:
		player.position.x = clampf(player.position.x, min_x, max_x)
		player.position.y = clampf(player.position.y, min_y, max_y)

func apply_visual_tilt(delta: float) -> void:
	if not player.sprite:
		return

	var current_max_spd = max(get_movement_speed(), 1.0)
	var dynamic_max_tilt = get_dynamic_max_tilt()

	var current_y_ratio = clampf(player.velocity.y / current_max_spd, -1.0, 1.0)
	var target_rotation = deg_to_rad(current_y_ratio * dynamic_max_tilt)
	player.sprite.rotation = lerpf(player.sprite.rotation, target_rotation, tilt_speed * delta)

# --- STAT & FORMULA HELPERS ---

func get_movement_speed() -> float:
	if player and player.stats_component:
		return player.stats_component.get_movement_speed()
	return 200.0

func get_dynamic_acceleration() -> float:
	var speed_ratio = get_movement_speed() / 200.0
	var agility = player.stats_component.get_agility_multiplier() if (player and player.stats_component) else 1.0
	return base_acceleration * pow(speed_ratio, 1.25) * agility

func get_dynamic_friction() -> float:
	var speed_ratio = get_movement_speed() / 200.0
	var agility = player.stats_component.get_agility_multiplier() if (player and player.stats_component) else 1.0
	return base_friction * pow(speed_ratio, 1.25) * agility

func get_dynamic_max_tilt() -> float:
	var speed_ratio = get_movement_speed() / 200.0
	return clampf(base_tilt_degrees * speed_ratio, 4.0, max_tilt_cap_degrees)

func get_tilt_angle() -> float:
	return player.sprite.rotation if (player and player.sprite) else 0.0