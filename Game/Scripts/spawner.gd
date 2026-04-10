class_name Spawner extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer
# @onready var boost_spawn_timer: Timer = $BoostSpawnTimer
@onready var pattern_gen: PatternGenerator = $PatternGenerator
@onready var game_manager: GameManager = $".."
@onready var label_manager: LabelManager = $"../LabelManager"
var ready_to_spawn : bool = false
var ready_to_boost: bool = false

var rng = RandomNumberGenerator.new()

static var min_y : float = 12
static var max_y : float = 110
static var spawn_pos_x : float = 250

const meteor = preload("res://Enemies/meteor.tscn")
var base_meteor_speed: float = 50
var base_meteor_health: float = 3
var base_meteor_damage: float = 1
var meteor_speed: float = base_meteor_speed
var meteor_damage: float = base_meteor_damage
var meteor_health: float = base_meteor_health

const ufo = preload("res://Enemies/ufo.tscn")
var base_ufo_speed: float = 40
var base_ufo_damage: float = 2
var base_ufo_health: float = 5
var ufo_speed: float = 40
var ufo_damage: float = 2
var ufo_health: float = 5

# const fire_boost = preload("res://Collectables/fire_booster.tscn")
# const attack_boost = preload("res://Collectables/attack_booster.tscn")
# var boost_speed: float = 50
# var boost_duration: float = 5

var base_min_enemy_gap: int = 40
var base_max_enemy_gap: int = 160
var base_min_enemy_count: int = 4
var base_max_enemy_count: int = 6
var min_enemy_gap: int = base_min_enemy_gap
var max_enemy_gap: int = base_max_enemy_gap
var min_enemy_count: int = base_min_enemy_count
var max_enemy_count: int = base_max_enemy_count

func _ready() -> void:
	await get_tree().process_frame
	set_ready_to_spawn(false)

func _process(_delta: float) -> void:
	pass

func adjust_difficulty_parameters(difficulty: float) -> void:
	var enemy_count_modifier: int = 1 * floor(2 * (difficulty-1))
	min_enemy_count = base_min_enemy_count + enemy_count_modifier
	max_enemy_count = base_max_enemy_count + enemy_count_modifier

func set_spawn_timer(new_time: int) -> void:
	spawn_timer.wait_time = new_time

func get_random_spawn_point() -> Array:
	var x: float = spawn_pos_x
	var y: float = rng.randf_range(min_y, max_y)
	return [x, y]

func kill_all_enemies() -> void:
	var scene = game_manager.get_parent()
	for child in scene.get_children():
		if child is EnemyMovement:
			child.queue_free()
	pass

func spawn_random_wave() -> void:
	var amount: int = rng.randi_range(min_enemy_count, max_enemy_count)
	var pattern = pattern_gen.get_random_points(amount, min_enemy_gap, max_enemy_gap, min_y, max_y)
	var enemy_type: GDScript = UfoMovement
	game_manager.increment_wave_count()
	print("Spawning wave %s:" % game_manager.get_wave_count())
	print("%s enemies" % amount)
	spawn_list(pattern, enemy_type)

func spawn_list(points: Array, enemy_type: GDScript) -> void:
	for point in points:
		var x: float = point[0] + spawn_pos_x
		var y: float = point[1]
		var enemy_position: Vector2 = Vector2(x, y)
		if enemy_type == MeteorMovement:
			spawn_enemy(enemy_position, MeteorMovement, meteor_damage, meteor_speed, meteor_health)
		elif enemy_type == UfoMovement:
			spawn_enemy(enemy_position, UfoMovement, ufo_damage, ufo_speed, ufo_health)

func spawn_enemy(enemy_position: Vector2, type: GDScript, damage: float, speed: float, health: float) -> void:
	var enemy_instance = type.spawn_enemy(damage, speed, health)
	get_node("/root/Playground").add_child(enemy_instance)
	enemy_instance.position = enemy_position

func spawn_at_random() -> void:
	var meteor_instance = meteor.instantiate()
	get_node("/root/Playground").add_child(meteor_instance)
	var point = get_random_spawn_point()
	meteor_instance.position.x = point[0]
	meteor_instance.position.y = point[1]

func set_ready_to_spawn(value: bool) -> void:
	var is_running = game_manager.get_running()
	if !is_running:
		return
	ready_to_spawn = value
	if ready_to_spawn:
		# print("ready to spawn - starting spawn timer")
		ready_to_spawn = false
		spawn_random_wave()
		spawn_timer.start()
		label_manager.show_wave_label()

func _on_spawn_timer_timeout() -> void:
	var is_running = game_manager.get_running()
	if !is_running:
		return
	# print("spawn timer timeout")
	game_manager.finish_wave()

# func _on_boost_spawn_timer_timeout() -> void:
# 	ready_to_boost = true

# func spawn_random_boost() -> void:
# 	var rand: int = rng.randi_range(0, 2)
# 	var boost: Collectable
# 	var point: Array = get_random_spawn_point()
# 	if rand == 0:
# 		boost = fire_boost.instantiate()
# 		spawn_boost(point, boost)
# 	elif rand == 1:
# 		boost = attack_boost.instantiate()
# 		spawn_boost(point, boost)
# 	elif rand == 2:
# 		boost = fire_boost.instantiate()
# 		spawn_boost(point, boost)
# 		point = get_random_spawn_point()
# 		boost = attack_boost.instantiate()
# 		spawn_boost(point, boost)

# func spawn_boost(point: Array, boost: Collectable) -> void:
# 	get_node("/root/Playground").add_child(boost)
# 	boost.position.x = point[0]
# 	boost.position.y = point[1]
# 	boost.set_speed(boost_speed)
# 	boost.set_duration(boost_duration)