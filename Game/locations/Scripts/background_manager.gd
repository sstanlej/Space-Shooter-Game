class_name BackgroundManager extends Node2D

var current_location: LocationData = null
var next_location: LocationData = null

@onready var current_location_node: Node2D = $CurrentLocation
@onready var next_location_node: Node2D = $NextLocation

@onready var current_back_sprite2d: Sprite2D = $"CurrentLocation/BackParallax/Sprite2D"
@onready var current_middle_sprite2d: Sprite2D = $"CurrentLocation/MiddleParallax/Sprite2D"
@onready var current_front_sprite2d: Sprite2D = $"CurrentLocation/FrontParallax/Sprite2D"

@onready var next_back_sprite2d: Sprite2D = $"NextLocation/BackParallax/Sprite2D"
@onready var next_middle_sprite2d: Sprite2D = $"NextLocation/MiddleParallax/Sprite2D"
@onready var next_front_sprite2d: Sprite2D = $"NextLocation/FrontParallax/Sprite2D"

@export var transition_duration: float = 4.0 # Czas trwania przejścia w sekundach

func _ready() -> void:
	# Upewniamy się, że na starcie Current jest widoczne, a Next całkowicie przezroczyste
	current_location_node.modulate.a = 1.0
	next_location_node.modulate.a = 0.0

func set_current_location(location: LocationData) -> void:
	current_location = location

func set_next_location(location: LocationData) -> void:
	next_location = location

func update_textures() -> void:
	if current_location:
		current_back_sprite2d.texture = current_location.background_texture
		current_middle_sprite2d.texture = current_location.middle_texture
		current_front_sprite2d.texture = current_location.front_texture
		print("Current location textures updated: %s" % current_location.location_name)
	if next_location:
		next_back_sprite2d.texture = next_location.background_texture
		next_middle_sprite2d.texture = next_location.middle_texture
		next_front_sprite2d.texture = next_location.front_texture
		print("Next location textures updated: %s" % next_location.location_name)

func transition_to_next_location() -> void:
	if next_location == current_location:
		print("Next location is the same as current location. No transition needed.")
		return
	var tween = create_tween().set_parallel(true)

	tween.tween_property(next_location_node, "modulate:a", 1.0, transition_duration)
	# tween.tween_property(current_location_node, "modulate:a", 0.0, transition_duration)

	tween.chain().tween_callback(_on_transition_finished)

func _on_transition_finished() -> void:
	current_location = next_location
	next_location = null

	update_textures()
	current_location_node.modulate.a = 1.0
	next_location_node.modulate.a = 0.0
