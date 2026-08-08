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
var next_location_index: int = 1
var map: Array[int] = []

func _ready() -> void:
	# Ustawienie przezroczystości węzłów tła
	if current_location_node and next_location_node:
		current_location_node.modulate.a = 1.0
		next_location_node.modulate.a = 0.0

	setup_map()

# --- LOGIKA SYSTEMU MAPY I LOKACJI ---

func setup_map() -> void:
	map.clear()
	# Pierwsze 3 fale w pierwszej lokacji (np. Kosmos)
	for i in range(3):
		map.append(0)

	generate_map(10)

	current_location_index = map[0]
	next_location_index = map[1]

	update_textures()

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

	print("[LocationManager] Wygenerowano mapę: ", map)

func advance_to_wave(wave_number: int) -> void:
	# Sprawdzamy czy nie brakuje nam mapy, jeśli tak – dogenerowujemy
	if wave_number - 1 >= map.size() - 1:
		generate_map(10)

	current_location_index = map[wave_number - 1]
	next_location_index = map[wave_number]

# --- AKTUALIZACJA TEKSTUR I TWEENOWANIE ---

func update_textures() -> void:
	var curr_loc = get_current_location()
	var next_loc = get_next_location()

	if curr_loc:
		if current_back_sprite: current_back_sprite.texture = curr_loc.background_texture
		if current_middle_sprite: current_middle_sprite.texture = curr_loc.middle_texture
		if current_front_sprite: current_front_sprite.texture = curr_loc.front_texture

	if next_loc:
		if next_back_sprite: next_back_sprite.texture = next_loc.background_texture
		if next_middle_sprite: next_middle_sprite.texture = next_loc.middle_texture
		if next_front_sprite: next_front_sprite.texture = next_loc.front_texture

func transition_to_next_location() -> void:
	var curr_loc = get_current_location()
	var next_loc = get_next_location()

	if curr_loc == next_loc:
		print("[LocationManager] Lokacja bez zmian: ", curr_loc.location_name)
		return

	print("[LocationManager] Rozpoczynam płynne przejście do: ", next_loc.location_name)

	# Przygotowanie tekstur następnej lokacji na podrzędnym węźle
	update_textures()
	next_location_node.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(next_location_node, "modulate:a", 1.0, transition_duration)
	tween.tween_callback(_on_transition_finished)

func _on_transition_finished() -> void:
	# Po zakończeniu animacji podmieniamy indeksy i resetujemy przezroczystość
	current_location_index = next_location_index
	update_textures()

	current_location_node.modulate.a = 1.0
	next_location_node.modulate.a = 0.0

# --- GETTERY ---

func get_current_location() -> LocationData:
	if current_location_index < locations.size():
		return locations[current_location_index]
	return null

func get_next_location() -> LocationData:
	if next_location_index < locations.size():
		return locations[next_location_index]
	return null
