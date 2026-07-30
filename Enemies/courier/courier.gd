class_name CourierEnemy extends Enemy

@export_group("Textures")
@export var normal_texture: Texture2D
@export var boost_texture: Texture2D

@export_group("Boost Settings")
@export var boost_speed_mult: float = 2.0
@export var min_boost_interval: float = 2.0
@export var max_boost_interval: float = 5.0
@export var boost_duration: float = 1.5

@export_group("Y-Movement Settings")
@export var min_y_change_interval: float = 1.5
@export var max_y_change_interval: float = 3.5
@export var y_change_speed: float = 3.0
@export var screen_margin: float = 25.0

@onready var sprite_node: Sprite2D = $Sprite2D

var is_boosting: bool = false
var target_y: float

func _ready() -> void:
	target_y = global_position.y
	schedule_next_boost()
	schedule_next_y_change()

func setup(enemy_data: EnemyData) -> void:
	super(enemy_data)
	target_y = global_position.y
	if normal_texture and sprite_node:
		sprite_node.texture = normal_texture

# BOOST LOGIC

func schedule_next_boost() -> void:
	var wait_time = randf_range(min_boost_interval, max_boost_interval)
	get_tree().create_timer(wait_time).timeout.connect(start_boost)

func start_boost() -> void:
	if not is_instance_valid(self):
		return

	is_boosting = true
	if boost_texture and sprite_node:
		sprite_node.texture = boost_texture

	get_tree().create_timer(boost_duration).timeout.connect(stop_boost)

func stop_boost() -> void:
	if not is_instance_valid(self):
		return

	is_boosting = false
	if normal_texture and sprite_node:
		sprite_node.texture = normal_texture

	schedule_next_boost()

# Y CHANGE LOGIC

func schedule_next_y_change() -> void:
	var wait_time = randf_range(min_y_change_interval, max_y_change_interval)
	get_tree().create_timer(wait_time).timeout.connect(change_target_y)

func change_target_y() -> void:
	if not is_instance_valid(self):
		return

	var screen_size = get_viewport_rect().size
	target_y = randf_range(screen_margin, screen_size.y - screen_margin)

	schedule_next_y_change()

# --- RUCH W KAŻDEJ KLATCE ---

func do_movement(delta: float) -> void:
	var current_speed = move_speed * (boost_speed_mult if is_boosting else 1.0)

	global_position.y = lerp(global_position.y, target_y, y_change_speed * delta)

	velocity.x = direction.x * current_speed
	velocity.y = 0

	move_and_slide()