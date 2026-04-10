class_name Spawner extends Node2D

@export var max_y : float = 110
@export var min_y : float = 12
@export var pos_x : float = 250
@export var spawn_point = [250, 65]
@onready var spawn_timer: Timer = $SpawnTimer
@onready var boost_spawn_timer: Timer = $BoostSpawnTimer
@onready var pattern_gen: PatternGenerator = $PatternGenerator
@onready var game_manager: GameManager = $".."
@onready var label_manager: LabelManager = $"../LabelManager"
var ready_to_spawn : bool
var ready_to_boost: bool = false

const meteor = preload("res://Enemies/meteor.tscn")
var meteor_speed: float = 50
var meteor_damage: float = 1
var meteor_health: float = 3

const ufo = preload("res://Enemies/ufo.tscn")
var ufo_speed: float = 40
var ufo_damage: float = 2
var ufo_health: float = 5

const fire_boost = preload("res://Collectables/fire_booster.tscn")
const attack_boost = preload("res://Collectables/attack_booster.tscn")
var boost_speed: float = 50
var boost_duration: float = 5

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	await get_tree().process_frame
	set_ready_to_spawn(true)

func _process(_delta: float) -> void:
	pass

func set_spawn_timer(new_time: int) -> void:
	spawn_timer.wait_time = new_time

func get_random_spawn_point() -> Array:
	var x: float = pos_x
	var y: float = rng.randf_range(min_y, max_y)
	return [x, y]

func spawn_random_boost() -> void:
	var rand: int = rng.randi_range(0, 2)
	var boost: Collectable
	var point: Array = get_random_spawn_point()
	if rand == 0:
		boost = fire_boost.instantiate()
		spawn_boost(point, boost)
	elif rand == 1:
		boost = attack_boost.instantiate()
		spawn_boost(point, boost)
	elif rand == 2:
		boost = fire_boost.instantiate()
		spawn_boost(point, boost)
		point = get_random_spawn_point()
		boost = attack_boost.instantiate()
		spawn_boost(point, boost)

func spawn_boost(point: Array, boost: Collectable) -> void:
	get_node("/root/Playground").add_child(boost)
	boost.position.x = point[0]
	boost.position.y = point[1]
	boost.set_speed(boost_speed)
	boost.set_duration(boost_duration)

func kill_all_enemies() -> void:
	var scene = game_manager.get_parent()
	for child in scene.get_children():
		if child is EnemyMovement:
			child.queue_free()
	pass

func spawn_random_wave() -> void:
	var n: int = rng.randi_range(5, 8)
	# var amp: int = rng.randi_range(40, 50)
	# var gap: int = rng.randi_range(30, 70)
	var min_gap: int = 30
	var max_gap: int = 70
	# var offset: int = rng.randi_range(0, 50)
	# var pattern = pattern_gen.get_sinusoid(n, amp, gap, offset)
	var pattern = pattern_gen.get_random_points(n, min_gap, max_gap, min_y, max_y)
	var enemies = GameManager.Enemies.METEOR
	game_manager.increment_wave_count()
	print("GM wave %s" % game_manager.get_wave_count())
	spawn_list(pattern, enemies)

func spawn_list(points: Array, enemies: GameManager.Enemies) -> void:
	for point in points:
		var x: float = point[0] + spawn_point[0]
		var y: float = point[1] # + spawn_point[1]
		if enemies == GameManager.Enemies.METEOR:
			spawn_meteor(x, y)
		elif enemies == GameManager.Enemies.UFO:
			spawn_ufo(x, y)

func spawn_meteor(x: float, y: float) -> void:
	# var score: float = game_manager.get_score()
	var speed_mult: float = 1 # + score / 100
	var meteor_instance = MeteorMovement.spawn_enemy(meteor_damage, meteor_speed * speed_mult, meteor_health)
	get_node("/root/Playground").add_child(meteor_instance)
	meteor_instance.position.x = x
	meteor_instance.position.y = y

func spawn_ufo(x: float, y: float) -> void:
	# var score: float = game_manager.get_score()
	var speed_mult: float = 1 # + score / 100
	var ufo_instance = UfoMovement.spawn_enemy(ufo_damage, ufo_speed * speed_mult, ufo_health)
	get_node("/root/Playground").add_child(ufo_instance)
	ufo_instance.position.x = x
	ufo_instance.position.y = y

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
		print("ready to spawn - starting spawn timer")
		ready_to_spawn = false
		spawn_random_wave()
		spawn_timer.start()
		label_manager.show_wave_label()

func _on_spawn_timer_timeout() -> void:
	var is_running = game_manager.get_running()
	if !is_running:
		return
	print("spawn timer timeout")
	game_manager.finish_wave()

func _on_boost_spawn_timer_timeout() -> void:
	ready_to_boost = true
