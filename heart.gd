class_name HeartTexture extends Sprite2D

var texture_on = preload("res://Game/Scripts/ui/Sprites/heart.png")
var texture_off = preload("res://Game/Scripts/ui/Sprites/heart_empty.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture = texture_on


func set_on(value: bool) -> void:
	if value:
		texture = texture_on
	else:
		texture = texture_off
