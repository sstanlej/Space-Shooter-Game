class_name Spawner extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer
@onready var game_manager: GameManager = $".."
@onready var label_manager: LabelManager = $"../LabelManager"
var ready_to_spawn : bool = false
var ready_to_boost: bool = false

var rng = RandomNumberGenerator.new()

static var min_y : int = 12
static var max_y : int = 110
static var spawn_pos_x : int = 250
static var middle_pos_y: int = 65

@export var base_min_enemy_gap: int = 40
@export var base_max_enemy_gap: int = 160
@export var max_enemy_gap_limit: int = 80
@export var base_min_enemy_count: int = 4
@export var base_max_enemy_count: int = 6
@export var min_enemy_gap: int = base_min_enemy_gap
@export var max_enemy_gap: int = base_max_enemy_gap
@export var min_enemy_count: int = base_min_enemy_count
@export var max_enemy_count: int = base_max_enemy_count

@export var ufo_chance: float = 0.1
@export var max_ufo_chance: float = 0.5

@export var clusterify_chance: float = 0.1
@export var min_cluster_vertical_distance: int = 15
@export var cluster_size: int = 3
@export var cluster_y_gap: int = 20
@export var cluster_x_gap: int = 20

var cluster_types = ["vertical", "horizontal", "key", "block", "rising", "falling"]

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

	ufo_chance = min(max_ufo_chance, difficulty/10)

	clusterify_chance = difficulty/10

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
	var wave_size: int = rng.randi_range(min_enemy_count, max_enemy_count)
	pattern.generate_random_base(wave_size, spawn_pos_x, min_enemy_gap, max_enemy_gap)

	var cluster_params = {
		"size": cluster_size,
		"gap_x": cluster_x_gap,
		"gap_y": cluster_y_gap,
		"size_x": cluster_size,
		"size_y": cluster_size
	}
	for i in range(pattern.get_size()):
		var r: float = rng.randf()
		if r < clusterify_chance:
			var cluster_type = cluster_types[rng.randi_range(0, cluster_types.size() - 1)]
			pattern.make_cluster(i, cluster_type, cluster_params)

	var enemy_types: Array
	for i in range(pattern.get_size()):
		enemy_types.append(MeteorMovement)
		# var r: float = rng.randf()
		# if r < ufo_chance:
		# 	enemy_types.append(UfoMovement)
		# else:
		# 	enemy_types.append(MeteorMovement)
	wave.set_pattern(pattern)
	wave.set_enemy_types(enemy_types)
	return wave

func spawn_wave() -> void:
	var wave1: Wave = generate_wave()
	print(wave1.get_pattern().get_pattern())
	game_manager.increment_wave_count()
	print("Spawning wave %s:" % game_manager.get_wave_count())
	print("%s enemies" % wave1.get_size())
	wave1.spawn(self)
	# Dodaj komunikat o zabiciu wsyzstkich wrogow danej fali i za to dodatkowe punkty

func spawn_random_wave() -> void:
	# kill_all_enemies()
	spawn_wave()

func spawn_enemy(enemy_position: Vector2, type: GDScript, damage: float, speed: float, health: float) -> void:
	var enemy_instance = type.spawn_enemy(damage, speed, health)
	get_node("/root/Playground").add_child(enemy_instance)
	enemy_instance.position = enemy_position
	var health_node = enemy_instance.get_node("HealthComponent")
	if enemy_instance.get_node("HealthComponent"): health_node.died.connect(game_manager._on_enemy_died)

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
	var is_wave_finished = game_manager.get_wave_finished()
	if not is_running or is_wave_finished:
		return
	# print("spawn timer timeout")
	game_manager.finish_wave()
