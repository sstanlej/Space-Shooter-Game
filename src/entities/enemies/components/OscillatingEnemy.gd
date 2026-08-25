class_name OscillatingEnemy extends Enemy

@export_group("Movement Settings")
@export var screen_margin: float = 25.0
@export var sine_frequency: float = 2.5
@export var sine_amplitude: float = 60.0

var time_passed: float = 0.0
var initial_y: float
var effective_amplitude: float

func setup(enemy_data: EnemyData) -> void:
	super(enemy_data)
	initial_y = global_position.y

	var screen_size = get_viewport_rect().size
	var max_allowed_amplitude = (screen_size.y - (screen_margin * 2.0)) / 2.0

	effective_amplitude = min(sine_amplitude, max_allowed_amplitude)

func do_movement(delta: float) -> void:
	time_passed += delta
	var screen_size = get_viewport_rect().size

	var min_y = screen_margin
	var max_y = screen_size.y - screen_margin

	var raw_target_y = initial_y + sin(time_passed * sine_frequency) * effective_amplitude

	if raw_target_y < min_y:
		var overlap = min_y - raw_target_y
		initial_y += overlap * 3.0 * delta
	elif raw_target_y > max_y:
		var overlap = raw_target_y - max_y
		initial_y -= overlap * 3.0 * delta

	var final_target_y = initial_y + sin(time_passed * sine_frequency) * effective_amplitude

	velocity.x = direction.x * move_speed
	global_position.y = final_target_y
	velocity.y = 0

	move_and_slide()
