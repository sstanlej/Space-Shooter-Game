class_name RotatorComponent extends Node

@export var target_sprite: CanvasItem
@export var rotation_speed: float = 0.6

func _ready() -> void:
	if not target_sprite and owner:
		target_sprite = owner.get_node_or_null("Sprite2D")

func _process(delta: float) -> void:
	if target_sprite:
		target_sprite.rotate(rotation_speed * delta)