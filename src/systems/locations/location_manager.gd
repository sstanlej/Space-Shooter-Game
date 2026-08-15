class_name LocationManager extends Node2D

@export_group("Fixed Sequence Locations")
## Lokacja startowa (Fala 1: 1 fala)
@export var starting_location: LocationData = load("res://src/systems/locations/resources/SpaceLocation.tres")

## Lokacja kosmosu (Fale 2-4: 3 fale)
@export var space_location: LocationData = load("res://src/systems/locations/resources/SpaceLocation.tres")

@export_group("Random Pool Locations")
## Pula do losowania kolejnych sektorów od Fali 5 wzwyż
@export var locations: Array[LocationData] = [
	load("res://src/systems/locations/resources/CityLocation.tres"),
	load("res://src/systems/locations/resources/GreenPlanetOrbitLocation.tres"),
	load("res://src/systems/locations/resources/MarsLocation.tres")
]

@export var transition_duration: float = 4.0

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
var previous_location: LocationData
var map: Array[LocationData] = []
var transition_tween: Tween

func _ready() -> void:
	if current_location_node:
		current_location_node.modulate.a = 1.0
	if next_location_node:
		next_location_node.modulate.a = 0.0

	setup_map()

# --- LOGIKA MAPY I SEKWENCJI ---

func setup_map() -> void:
	map.clear()

	# 1. Fala 1: Earth Orbit (1 fala)
	var first_loc = starting_location if starting_location else (locations[0] if not locations.is_empty() else null)
	if first_loc:
		map.append(first_loc)

	# 2. Fale 2-4: Space (3 fale)
	var second_loc = space_location if space_location else (locations[0] if not locations.is_empty() else null)
	if second_loc:
		for i in range(3):
			map.append(second_loc)

	# 3. Kolejne losowe strefy od Fali 5
	generate_map(10)

	current_location = map[0] if not map.is_empty() else null
	previous_location = current_location

	if current_location:
		apply_textures_to_node(current_location, current_back_sprite, current_middle_sprite, current_front_sprite)

	print_map_summary()

func generate_map(amount_of_zones: int) -> void:
	if locations.is_empty():
		return

	var last_loc: LocationData = map[map.size() - 1] if not map.is_empty() else null

	for i in range(amount_of_zones):
		var available_pool = locations.filter(func(loc): return loc != last_loc and loc != null)
		var chosen_loc: LocationData = available_pool.pick_random() if not available_pool.is_empty() else locations.pick_random()

		if not chosen_loc:
			continue

		var duration = randi_range(2, 4)
		for j in range(duration):
			map.append(chosen_loc)

		last_loc = chosen_loc

func advance_to_wave(wave_number: int) -> void:
	var target_index = wave_number - 1

	while target_index >= map.size():
		generate_map(10)
		print_map_summary()

	previous_location = current_location
	current_location = map[target_index]

# --- MINIMALISTYCZNY LOG KONSOLI ---

func print_map_summary() -> void:
	if map.is_empty():
		print("[LocationManager] Map is empty.")
		return

	print("[LocationManager] Map sequence:")
	var current_tracked = map[0]
	var count = 0

	for loc in map:
		if loc == current_tracked:
			count += 1
		else:
			var loc_name = current_tracked.location_name if current_tracked and not current_tracked.location_name.is_empty() else "Unknown"
			print("  - %s: %d waves" % [loc_name, count])
			current_tracked = loc
			count = 1

	var last_name = current_tracked.location_name if current_tracked and not current_tracked.location_name.is_empty() else "Unknown"
	print("  - %s: %d waves" % [last_name, count])

# --- PRZEJŚCIA POMIĘDZY LOKACJAMI ---

func apply_textures_to_node(loc_data: LocationData, back_sp: Sprite2D, mid_sp: Sprite2D, front_sp: Sprite2D) -> void:
	if not loc_data:
		return
	if back_sp:
		back_sp.texture = loc_data.background_texture
	if mid_sp:
		mid_sp.texture = loc_data.middle_texture
	if front_sp:
		front_sp.texture = loc_data.front_texture

func transition_to_next_location() -> void:
	if not current_location or previous_location == current_location:
		return

	var old_name = previous_location.location_name if previous_location else "None"
	var new_name = current_location.location_name if current_location else "None"
	print("[LocationManager] Transition: '%s' -> '%s'" % [old_name, new_name])

	apply_textures_to_node(previous_location, current_back_sprite, current_middle_sprite, current_front_sprite)
	if current_location_node:
		current_location_node.modulate.a = 1.0

	apply_textures_to_node(current_location, next_back_sprite, next_middle_sprite, next_front_sprite)
	if next_location_node:
		next_location_node.modulate.a = 0.0

	if transition_tween and transition_tween.is_running():
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.tween_property(next_location_node, "modulate:a", 1.0, transition_duration)
	transition_tween.tween_callback(_on_transition_finished)

func _on_transition_finished() -> void:
	apply_textures_to_node(current_location, current_back_sprite, current_middle_sprite, current_front_sprite)
	if current_location_node:
		current_location_node.modulate.a = 1.0
	if next_location_node:
		next_location_node.modulate.a = 0.0
	previous_location = current_location

# --- GETTER ---

func get_current_location() -> LocationData:
	return current_location