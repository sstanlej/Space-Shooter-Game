class_name Spawner extends Node2D

@export var max_y : float = 120
@export var min_y : float = 12
@export var pos_x : float = 250
@onready var spawn_timer: Timer = $SpawnTimer
var is_ready : bool = true
const meteor = preload("res://Enemies/meteor.tscn")
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_ready:
		is_ready = false
		var meteor_instance = meteor.instantiate()
		get_node("/root/Playground").add_child(meteor_instance)
		# add_child(meteor_instance)
		meteor_instance.position.x = pos_x
		meteor_instance.position.y = rng.randf_range(min_y, max_y)
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	is_ready = true
