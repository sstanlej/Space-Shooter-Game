class_name Heart extends Sprite2D

static var texture_on = preload("res://Game/ui/Sprites/heart.png")
static var texture_off = preload("res://Game/ui/Sprites/heart_empty.png")
static var my_scene: PackedScene = preload("res://Game/ui/heart.tscn")

static func spawn_heart() -> Heart:
	return my_scene.instantiate()

func _ready() -> void:
	texture = texture_on

static func set_textures(new_texture_on: Texture, new_texture_off: Texture) -> void:
	texture_on = new_texture_on
	texture_off = new_texture_off

func set_on(value: bool) -> void:
	if value:
		texture = texture_on
	else:
		texture = texture_off
