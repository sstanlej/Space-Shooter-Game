class_name Spawner extends Node2D

@export var max_y : float = 120
@export var min_y : float = 12
@export var pos_x : float = 250
@export var start_point = [250, 65]
@onready var spawn_timer: Timer = $SpawnTimer
@onready var pattern_gen: PatternGenerator = $PatternGenerator
var is_ready : bool = true
const meteor = preload("res://Enemies/meteor.tscn")
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	var points = pattern_gen.get_sinusoid(30, 50, 30)
	spawn_list(points)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# spawn_at_random()
	pass

func spawn_list(points: Array) -> void:
	for point in points:
		point[0] += start_point[0]
		point[1] += start_point[1]
		var meteor_instance = meteor.instantiate()
		get_node("/root/Playground").add_child(meteor_instance)
		meteor_instance.position.x = point[0]
		meteor_instance.position.y = point[1]
		print([point])

func spawn_at_random() -> void:
	if is_ready:
		is_ready = false
		var meteor_instance = meteor.instantiate()
		get_node("/root/Playground").add_child(meteor_instance)
		# add_child(meteor_instance)
		var x: float = pos_x
		var y: float = rng.randf_range(min_y, max_y)
		meteor_instance.position.x = x
		meteor_instance.position.y = y
		print([x, y])
		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	is_ready = true
