class_name LocationManager extends Node2D

@export_group("Locations Data")
@export var locations: Array[LocationData] = [
	load("res://src/systems/locations/resources/SpaceLocation.tres"),
	load("res://src/systems/locations/resources/CityLocation.tres"),
	load("res://src/systems/locations/resources/GreenPlanetOrbitLocation.tres"),
	load("res://src/systems/locations/resources/MarsLocation.tres")
]
@export var transition_duration: float = 4.0

@export_group("Scene References")
@onready var current_location_node: Node2D = $CurrentLocation
@onready var next_location_node: Node2D = $NextLocation

@onready var current_back_sprite: Sprite2D = $CurrentLocation/BackParallax/Sprite2D
@onready var current_middle_sprite: Sprite2D = $CurrentLocation/MiddleParallax/Sprite2D
@onready var current_front_sprite: Sprite2D = $CurrentLocation/FrontParallax/Sprite2D

@onready var next_back_sprite: Sprite2D = $NextLocation/BackParallax/Sprite2D
@onready var next_middle_sprite: Sprite2D = $NextLocation/MiddleParallax/Sprite2D
@onready var next_front_sprite: Sprite2D = $NextLocation/FrontParallax/Sprite2D

var current_location_index: int = 0
var previous_location_index: int = 0
var map: Array[int] = []

func _ready() -> void:
	if current_location_node and next_location_node:
		current_location_node.modulate.a = 1.0
		next_location_node.modulate.a = 0.0

	setup_map()

# --- LOGIKA SYSTEMU MAPY I LOKACJI ---

func setup_map() -> void:
	map.clear()
	for i in range(3):
		map.append(0)

	generate_map(10)

	current_location_index = map[0]
	previous_location_index = map[0]

	apply_textures_to_node(get_current_location(), current_back_sprite, current_middle_sprite, current_front_sprite)

func generate_map(locations_amount: int) -> void:
	var sequence = []
	var max_value = locations.size() - 1
	var min_value = 0
	var last_value = map[map.size() - 1] if map.size() > 0 else -1

	for i in range(locations_amount):
		var new_value = randi_range(min_value, max_value)
		while new_value == last_value:
			new_value = randi_range(min_value, max_value)
		sequence.append(new_value)
		last_value = new_value

	for i in sequence:
		var duration = randi_range(2, 4)
		for j in range(duration):
			map.append(i)
		# map.append(i)

	print("[LocationManager] Wygenerowano mapę: ", map)

func advance_to_wave(wave_number: int) -> void:
	if wave_number - 1 >= map.size() - 1:
		generate_map(10)

	# Zapamiętujemy poprzednią lokację przed zmianą
	previous_location_index = current_location_index
	# Nowa lokacja dla Spawnera wchodzi NATYCHMIAST!
	current_location_index = map[wave_number - 1]

# --- AKTUALIZACJA TEKSTUR I TWEENOWANIE ---

func apply_textures_to_node(loc_data: LocationData, back_sp: Sprite2D, mid_sp: Sprite2D, front_sp: Sprite2D) -> void:
	if not loc_data:
		return
	if back_sp: back_sp.texture = loc_data.background_texture
	if mid_sp: mid_sp.texture = loc_data.middle_texture
	if front_sp: front_sp.texture = loc_data.front_texture

func transition_to_next_location() -> void:
	# Jeśli nowa lokacja z mapy jest taka sama jak poprzednia – brak animacji
	if previous_location_index == current_location_index:
		print("[LocationManager] Lokacja bez zmian: ", get_current_location().location_name)
		return

	var old_loc = locations[previous_location_index]
	var new_loc = get_current_location()

	print("[LocationManager] Rozpoczynam płynne przejście z '", old_loc.location_name, "' do '", new_loc.location_name, "'")

	# 1. Stara lokacja idzie na spodni węzeł (widoczny)
	apply_textures_to_node(old_loc, current_back_sprite, current_middle_sprite, current_front_sprite)
	current_location_node.modulate.a = 1.0

	# 2. Nowa lokacja idzie na wierzchni węzeł (przezroczysty na start)
	apply_textures_to_node(new_loc, next_back_sprite, next_middle_sprite, next_front_sprite)
	next_location_node.modulate.a = 0.0

	# 3. Płynne przenikanie (Cross-Fade)
	var tween = create_tween()
	tween.tween_property(next_location_node, "modulate:a", 1.0, transition_duration)
	tween.tween_callback(_on_transition_finished)

func _on_transition_finished() -> void:
	# Po zakończeniu przechodzenia przypisujemy nową lokację na stałe na głównym węźle
	apply_textures_to_node(get_current_location(), current_back_sprite, current_middle_sprite, current_front_sprite)
	current_location_node.modulate.a = 1.0
	next_location_node.modulate.a = 0.0
	previous_location_index = current_location_index

# --- GETTERY ---

func get_current_location() -> LocationData:
	if current_location_index < locations.size():
		return locations[current_location_index]
	return null
