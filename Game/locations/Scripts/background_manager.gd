class_name BackgroundManager extends Node2D

var current_location: LocationData = null
var next_location: LocationData = null
@onready var current_back_sprite2d: Sprite2D = $"CurrentLocation/BackParallax/Sprite2D"
@onready var current_middle_sprite2d: Sprite2D = $"CurrentLocation/MiddleParallax/Sprite2D"
@onready var current_front_sprite2d: Sprite2D = $"CurrentLocation/FrontParallax/Sprite2D"
@onready var next_back_sprite2d: Sprite2D = $"NextLocation/BackParallax/Sprite2D"
@onready var next_middle_sprite2d: Sprite2D = $"NextLocation/MiddleParallax/Sprite2D"
@onready var next_front_sprite2d: Sprite2D = $"NextLocation/FrontParallax/Sprite2D"

func set_current_location(location: LocationData) -> void:
	current_location = location

func set_next_location(location: LocationData) -> void:
	next_location = location

func update_textures() -> void:
	if current_location:
		current_back_sprite2d.texture = current_location.background_texture
		current_middle_sprite2d.texture = current_location.middle_texture
		current_front_sprite2d.texture = current_location.front_texture
	if next_location:
		next_back_sprite2d.texture = next_location.background_texture
		next_middle_sprite2d.texture = next_location.middle_texture
		next_front_sprite2d.texture = next_location.front_texture

func transition_to_next_location() -> void:
	if next_location:
		current_location = next_location
		next_location = null
	update_textures()
