class_name Collectable extends CharacterBody2D

@export var speed: float = 30
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_speed(new_speed: float) -> void:
	speed = new_speed

func _physics_process(_delta: float) -> void:
	move_left()

func move_left() -> void:
	velocity = Vector2.LEFT * speed
	move_and_slide()

func affect_player() -> void:
	pass

func get_player(area: Area2D) -> Player:
	if area.get_parent() is Player:
		player = area.get_parent()
		return player
	return null

func _on_area_2d_area_entered(area: Area2D) -> void:
	player = get_player(area)
	if !player:
		return
	hide()
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
	affect_player()
