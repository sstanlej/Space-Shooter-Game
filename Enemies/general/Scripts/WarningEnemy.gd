class_name WarningEnemy extends Enemy

@export var warning_duration: float = 0.6
@export var warning_indicator_scene: PackedScene

var is_charging: bool = false

func _ready() -> void:
	is_charging = false

func setup(enemy_data: EnemyData) -> void:
	super(enemy_data)

	var screen_right = get_viewport_rect().size.x
	global_position.x = screen_right + 30.0

	spawn_warning_indicator(screen_right)

	get_tree().create_timer(warning_duration).timeout.connect(_on_warning_finished)

func spawn_warning_indicator(screen_x: float) -> void:
	if warning_indicator_scene:
		var indicator = warning_indicator_scene.instantiate() as WarningIndicator
		var indicator_pos = Vector2(screen_x - 15.0, global_position.y)

		get_parent().add_child(indicator)
		indicator.setup(warning_duration, indicator_pos)

func _on_warning_finished() -> void:
	is_charging = true

func do_movement(_delta: float) -> void:
	if not is_charging:
		velocity = Vector2.ZERO
		return

	velocity = direction * move_speed
	move_and_slide()