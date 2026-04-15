class_name Spawner extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer
# @onready var boost_spawn_timer: Timer = $BoostSpawnTimer
@onready var game_manager: GameManager = $".."
@onready var label_manager: LabelManager = $"../LabelManager"
var ready_to_spawn : bool = false
var ready_to_boost: bool = false

var rng = RandomNumberGenerator.new()

static var min_y : float = 12
static var max_y : float = 90
static var spawn_pos_x : int = 250
static var middle_pos_y: int = 65

const meteor = preload("res://Enemies/meteor.tscn")
var base_meteor_speed: float = 75
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
var max_enemy_gap_limit: int = 80
var base_min_enemy_count: int = 4
var base_max_enemy_count: int = 6
var min_enemy_gap: int = base_min_enemy_gap
var max_enemy_gap: int = base_max_enemy_gap
var min_enemy_count: int = base_min_enemy_count
var max_enemy_count: int = base_max_enemy_count

var ufo_threshold: float = 0.1

var min_cluster_vertical_distance: int = 15

func _ready() -> void:
	await get_tree().process_frame
	set_ready_to_spawn(false)

func _process(_delta: float) -> void:
	pass

func adjust_difficulty_parameters(difficulty: float) -> void:
	var enemy_count_modifier: int = 1 * floor(2 * (difficulty-1))
	min_enemy_count = base_min_enemy_count + enemy_count_modifier
	max_enemy_count = base_max_enemy_count + enemy_count_modifier

	var enemy_gap_modifier: float = 20 * (difficulty-1)
	max_enemy_gap = base_max_enemy_gap - int(enemy_gap_modifier)
	if max_enemy_gap < max_enemy_gap_limit: max_enemy_gap = max_enemy_gap_limit

	ufo_threshold = difficulty/10

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

func generate_wave() -> Wave:
	var wave: Wave = Wave.new()
	var pattern: Pattern = Pattern.new()
	# pattern1.add_random_points()
	return wave

func spawn_random_wave() -> void:
	# NEW PATTERN GENERATION
	var pattern1: Pattern = Pattern.new()
	var amount: int = rng.randi_range(min_enemy_count, max_enemy_count)
	pattern1.add_random_points(amount, spawn_pos_x, min_enemy_gap, max_enemy_gap, min_y, max_y)
	print(pattern1.get_size())
	pattern1.clusterify(2, 3, 20)
	# var gap_x: int = rng.randi_range(min_enemy_gap, max_enemy_gap)
	# pattern1.add_cluster(5, gap_x, 30, [])
	# pattern1.add_cluster(3, gap_x, 15, [])

	# TYPE OF ENEMY SPAWNED
	var enemy_types: Array
	for i in range(pattern1.get_size()):
		var r: float = rng.randf()
		if r > ufo_threshold:
			enemy_types.append(MeteorMovement)
		else:
			enemy_types.append(UfoMovement)

	game_manager.increment_wave_count()
	print("Spawning wave %s:" % game_manager.get_wave_count())
	print("%s enemies" % amount)
	var wave1: Wave = Wave.new()
	wave1.set_pattern(pattern1)
	wave1.set_enemy_types(enemy_types)
	wave1.spawn(self)
	# spawn_list(pattern1.get_pattern(), enemy_type)
	print(pattern1.get_pattern())
	print(pattern1.get_x_indexes())
	print(pattern1.get_y_indexes())

func spawn_enemy(enemy_position: Vector2, type: GDScript, damage: float, speed: float, health: float) -> void:
	var enemy_instance = type.spawn_enemy(damage, speed, health)
	get_node("/root/Playground").add_child(enemy_instance)
	enemy_instance.position = enemy_position

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
