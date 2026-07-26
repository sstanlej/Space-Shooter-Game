class_name BackgroundManager extends Node2D

var current_location: LocationData = null
var next_location: LocationData = null
@onready var current_back_parallax: Parallax2D = $"CurrentLocation/BackParallax"
@onready var current_middle_parallax: Parallax2D = $"CurrentLocation/MiddleParallax"
@onready var current_front_parallax: Parallax2D = $"CurrentLocation/FrontParallax"
@onready var next_back_parallax: Parallax2D = $"NextLocation/BackParallax"
@onready var next_middle_parallax: Parallax2D = $"NextLocation/MiddleParallax"
@onready var next_front_parallax: Parallax2D = $"NextLocation/FrontParallax"

func set_current_location(location: LocationData) -> void:
	current_location = location

func set_next_location(location: LocationData) -> void:
	next_location = location

func update_textures() -> void:
	if current_location:
		current_back_parallax.texture = current_location.back_texture
		current_middle_parallax.texture = current_location.middle_texture
		current_front_parallax.texture = current_location.front_texture
	if next_location:
		next_back_parallax.texture = next_location.back_texture
		next_middle_parallax.texture = next_location.middle_texture
		next_front_parallax.texture = next_location.front_texture

func transition_to_next_location() -> void:
	if next_location:
		current_location = next_location
		next_location = null
	update_textures()
