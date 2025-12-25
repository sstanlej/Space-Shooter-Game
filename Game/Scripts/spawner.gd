class_name Spawner extends Node2D

@export var max_y : float = 120
@export var min_y : float = 12
@export var pos_x : float = 250
@export var spawn_point = [250, 65]
@onready var spawn_timer: Timer = $SpawnTimer
@onready var pattern_gen: PatternGenerator = $PatternGenerator
var is_ready : bool = true
var wave_count: int = 0
const meteor = preload("res://Enemies/meteor.tscn")
const fire_boost = preload("res://Collectables/fire_booster.tscn")
var rng = RandomNumberGenerator.new()

func get_random_spawn_point() -> Array:
	var x: float = pos_x
	var y: float = rng.randf_range(min_y, max_y)
	return [x, y]

func _ready() -> void:
	await get_tree().process_frame
	# var spawn_points = pattern_gen.get_sinusoid(30, 50, 30)
	# spawn_list(spawn_points)
	pass

func spawn_fire_boost(point: Array, speed: float) -> void:
	var boost_instance: Collectable = fire_boost.instantiate()
	get_node("/root/Playground").add_child(boost_instance)
	boost_instance.position.x = point[0]
	boost_instance.position.y = point[1]
	boost_instance.set_speed(speed)

func _process(_delta: float) -> void:
	var is_running = get_parent().get_running()
	if is_ready and is_running:
		is_ready = false
		spawn_random_wave()
		spawn_fire_boost(get_random_spawn_point(), 50)
	#if !is_running:
		#kill_everything()

func kill_everything() -> void:
	var scene = get_parent().get_parent()
	for child in scene.get_children():
		if child is EnemyMovement:
			child.queue_free()
	pass

func spawn_random_wave() -> void:
	var n: int = rng.randi_range(4, 12)
	var amp: int = rng.randi_range(40, 50)
	var gap: int = rng.randi_range(10, 50)
	var offset: int = rng.randi_range(0, 50)
	var spawn_points = pattern_gen.get_sinusoid(n, amp, gap, offset)
	wave_count += 1
	print("Wave %s" % wave_count)
	spawn_list(spawn_points)
	spawn_timer.start()

func spawn_list(points: Array) -> void:
	for point in points:
		var x: float = point[0] + spawn_point[0]
		var y: float = point[1] + spawn_point[1]
		var meteor_instance = meteor.instantiate()
		get_node("/root/Playground").add_child(meteor_instance)
		meteor_instance.position.x = x
		meteor_instance.position.y = y
		
		var score: float = get_parent().get_score()
		var speed_mult: float = 1 + score / 400
		var new_speed = meteor_instance.get_move_speed() * speed_mult
		meteor_instance.set_move_speed(new_speed)

func spawn_at_random() -> void:
	var meteor_instance = meteor.instantiate()
	get_node("/root/Playground").add_child(meteor_instance)		# add_child(meteor_instance)
	var point = get_random_spawn_point()
	meteor_instance.position.x = point[0]
	meteor_instance.position.y = point[1]
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	is_ready = true
