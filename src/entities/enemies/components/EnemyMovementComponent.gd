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
var base_pos: Vector2 = Vector2.ZERO
var time_passed: float = 0.0
var effective_amplitude: float = 0.0
var can_move: bool = true

@onready var body: CharacterBody2D = owner as CharacterBody2D

func _ready() -> void:
	if body:
		base_pos = body.global_position
	direction = direction.normalized()
	calculate_amplitude()

func on_enemy_setup() -> void:
	if body:
		base_pos = body.global_position
	direction = direction.normalized()

func calculate_amplitude() -> void:
	var screen_size = body.get_viewport_rect().size if body else Vector2(320, 180)
	var max_allowed = (screen_size.y - (screen_margin * 2.0)) / 2.0
	effective_amplitude = min(sine_amplitude, max_allowed)

func setup_from_data(speed: float, initial_pos: Vector2) -> void:
	move_speed = speed
	base_pos = initial_pos
	calculate_amplitude()

func move(delta: float) -> void:
	if not body or not can_move:
		return

	var current_speed = move_speed * speed_multiplier

	match mode:
		MovementMode.LINEAR:
			body.velocity = direction * current_speed
			body.move_and_slide()

		MovementMode.SINE_WAVE:
			time_passed += delta
			base_pos += direction * current_speed * delta
			
			# Wektor prostopadły do kierunku ruchu dla fali sinusoidalnej
			var perp = Vector2(-direction.y, direction.x)
			var offset = perp * (sin(time_passed * sine_frequency) * effective_amplitude)
			
			body.global_position = base_pos + offset