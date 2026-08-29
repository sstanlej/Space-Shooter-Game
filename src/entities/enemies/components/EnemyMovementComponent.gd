class_name EnemyMovementComponent extends Node

enum MovementMode { LINEAR, SINE_WAVE }

@export var mode: MovementMode = MovementMode.LINEAR
@export var move_speed: float = 30.0
@export var direction: Vector2 = Vector2.LEFT

@export_group("Sine Wave Settings")
@export var sine_frequency: float = 2.5
@export var sine_amplitude: float = 45.0
@export var screen_margin: float = 25.0

var speed_multiplier: float = 1.0
var base_y: float = 0.0
var time_passed: float = 0.0
var effective_amplitude: float = 0.0
var can_move: bool = true

@onready var body: CharacterBody2D = owner as CharacterBody2D

func _ready() -> void:
	if body:
		base_y = body.global_position.y
	calculate_amplitude()

func on_enemy_setup() -> void:
	if body:
		base_y = body.global_position.y

func calculate_amplitude() -> void:
	var screen_size = body.get_viewport_rect().size if body else Vector2(320, 180)
	var max_allowed = (screen_size.y - (screen_margin * 2.0)) / 2.0
	effective_amplitude = min(sine_amplitude, max_allowed)

func setup_from_data(speed: float, initial_y: float) -> void:
	move_speed = speed
	base_y = initial_y
	calculate_amplitude()

func move(delta: float) -> void:
	if not body or not can_move:
		return

	var current_speed = move_speed * speed_multiplier

	if direction.y != 0.0:
		base_y += direction.y * current_speed * delta

	match mode:
		MovementMode.LINEAR:
			body.velocity.x = direction.x * current_speed
			body.velocity.y = 0.0
			body.global_position.y = base_y
			body.move_and_slide()

		MovementMode.SINE_WAVE:
			time_passed += delta
			var screen_size = body.get_viewport_rect().size
			var min_y = screen_margin
			var max_y = screen_size.y - screen_margin

			var raw_target_y = base_y + sin(time_passed * sine_frequency) * effective_amplitude

			if raw_target_y < min_y:
				base_y += (min_y - raw_target_y) * 3.0 * delta
			elif raw_target_y > max_y:
				base_y -= (raw_target_y - max_y) * 3.0 * delta

			var final_target_y = base_y + sin(time_passed * sine_frequency) * effective_amplitude

			body.velocity.x = direction.x * current_speed
			body.velocity.y = 0.0
			body.global_position.y = final_target_y
			body.move_and_slide()