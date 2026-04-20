class_name Heart extends Sprite2D

var texture_on = preload("res://Game/Scripts/ui/Sprites/heart.png")
var texture_off = preload("res://Game/Scripts/ui/Sprites/heart_empty.png")
static var my_scene: PackedScene = preload("res://Game/Scripts/ui/heart.tscn")

static func spawn_heart() -> Heart:
	return my_scene.instantiate()

func _ready() -> void:
	texture = texture_on

func set_on(value: bool) -> void:
	if value:
		texture = texture_on
	else:
		texture = texture_off
