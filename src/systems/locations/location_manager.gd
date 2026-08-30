class_name LocationManager extends Node2D

@export_group("Transition Settings")
@export var transition_duration: float = 3.5

@export_group("Scene References")
@onready var current_location_node: Node2D = get_node_or_null("CurrentLocation")
@onready var next_location_node: Node2D = get_node_or_null("NextLocation")

@onready var current_back_sprite: Sprite2D = get_node_or_null("CurrentLocation/BackParallax/Sprite2D")
@onready var current_middle_sprite: Sprite2D = get_node_or_null("CurrentLocation/MiddleParallax/Sprite2D")
@onready var current_front_sprite: Sprite2D = get_node_or_null("CurrentLocation/FrontParallax/Sprite2D")

@onready var next_back_sprite: Sprite2D = get_node_or_null("NextLocation/BackParallax/Sprite2D")
@onready var next_middle_sprite: Sprite2D = get_node_or_null("NextLocation/MiddleParallax/Sprite2D")
@onready var next_front_sprite: Sprite2D = get_node_or_null("NextLocation/FrontParallax/Sprite2D")

var current_location: LocationData
var transition_tween: Tween

func _ready() -> void:
	if current_location_node:
		current_location_node.modulate.a = 1.0
	if next_location_node:
		next_location_node.modulate.a = 0.0

# --- LOCATION SETUP & TRANSITIONS ---

func set_initial_location(loc_data: LocationData) -> void:
	if not loc_data:
		return

	current_location = loc_data
	var loc_name = current_location.location_name if not current_location.location_name.is_empty() else "Unknown"
	print("[LocationManager] Initial location set to: '%s'" % loc_name)

	apply_textures_to_node(current_location, current_back_sprite, current_middle_sprite, current_front_sprite)
	if current_location_node:
		current_location_node.modulate.a = 1.0
	if next_location_node:
		next_location_node.modulate.a = 0.0

func transition_to_location(new_location: LocationData) -> void:
	if not new_location or new_location == current_location:
		return

	var from_name = current_location.location_name if current_location and not current_location.location_name.is_empty() else "None"
	var to_name = new_location.location_name if not new_location.location_name.is_empty() else "Unknown"
	print("[LocationManager] Starting transition: '%s' -> '%s' (Duration: %.1fs)" % [from_name, to_name, transition_duration])

	apply_textures_to_node(current_location, current_back_sprite, current_middle_sprite, current_front_sprite)
	if current_location_node:
		current_location_node.modulate.a = 1.0

	apply_textures_to_node(new_location, next_back_sprite, next_middle_sprite, next_front_sprite)
	if next_location_node:
		next_location_node.modulate.a = 0.0

	if transition_tween and transition_tween.is_running():
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.tween_property(next_location_node, "modulate:a", 1.0, transition_duration)
	transition_tween.tween_callback(_on_transition_finished.bind(new_location))

func _on_transition_finished(new_location: LocationData) -> void:
	apply_textures_to_node(new_location, current_back_sprite, current_middle_sprite, current_front_sprite)
	if current_location_node:
		current_location_node.modulate.a = 1.0
	if next_location_node:
		next_location_node.modulate.a = 0.0

	current_location = new_location
	var loc_name = current_location.location_name if not current_location.location_name.is_empty() else "Unknown"
	print("[LocationManager] Transition finished. Active location: '%s'" % loc_name)

func apply_textures_to_node(loc_data: LocationData, back_sp: Sprite2D, mid_sp: Sprite2D, front_sp: Sprite2D) -> void:
	if not loc_data:
		return
	if back_sp:
		back_sp.texture = loc_data.background_texture
	if mid_sp:
		mid_sp.texture = loc_data.middle_texture
	if front_sp:
		front_sp.texture = loc_data.front_texture

func get_current_location() -> LocationData:
	return current_location