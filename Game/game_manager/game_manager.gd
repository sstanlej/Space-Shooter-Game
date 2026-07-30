class_name GameManager extends Node2D

@onready var player: Player = $"../Player"
@onready var player_attack_controler: AttackControler = $"../Player/AttackControler"
@onready var player_health: HealthComponent = $"../Player/HealthComponent"
@onready var spawner: Spawner = $Spawner
@export var shop_manager: ShopManager
@onready var label_manager: LabelManager = $LabelManager
@onready var ui_manager: UIManager = $"../UICanvasLayer/UIControl/UIManager"
@export var wave_cooldown_timer: Timer
@export var debug_panel: DebugPanel
@export var camera_frame: CameraFrame
@onready var background_manager: BackgroundManager = $"../BackgroundManager"

enum Enemies {
	METEOR,
	UFO
}

var is_running: bool = false
var is_player_alive: bool = true
var score : float = 0
var escaped: int
var wave_count: int = 0
var difficulty: float = 1
@export var difficulty_wave_gain: float = 0.15
@export var wave_duration: int = 10
@export var wave_cooldown: int = 5
var wave_finished: bool = false
var distance: float = 0

var experience: int
var experience_needed: int = 100
var level: int = 1
var experience_needed_modifier: float = 1.2

var locations: Array[LocationData] = [load("res://Game/locations/Resources/SpaceLocation.tres"),
										load("res://Game/locations/Resources/CityLocation.tres"),
										load("res://Game/locations/Resources/GreenPlanetOrbitLocation.tres"),]
var current_location_index: int = 0
var next_location_index: int = 1
var map: Array[int] = []

func _ready() -> void:
	await get_tree().process_frame
	setup_map()
	wait_to_start()

func _process(_delta: float):
	if not is_running:
		return
	distance += _delta
	ui_manager.update_distance_label(distance)

func wait_to_start() -> void:
	camera_frame.move_to_menu_view()
	set_player(false)
	wave_cooldown_timer.wait_time = wave_cooldown
	spawner.set_spawn_timer(wave_duration)

func start_game() -> void:
	is_running = true
	wave_count = 1
	ui_manager.hide_start_game_label()
	play_start_animation()
	is_player_alive = true
	spawner.set_ready_to_spawn(true)
	label_manager.configure_default_labels()
	label_manager.show_wave_label()
	update_player_health_label()

func play_start_animation() -> void:
	var _camera_tween = camera_frame.move_to_game_view()
	var player_tween = player.move_to_game_view()
	await player_tween.finished
	set_player(true)

func get_distance() -> float:
	return distance

func finish_wave() -> void:
	print("Finishing wave")
	set_wave_finished(true)
	label_manager.show_wave_finished_label()

	add_difficulty(difficulty_wave_gain)
	spawner.adjust_difficulty_parameters(difficulty)
	print("New difficulty: %s" % difficulty)

	wave_cooldown_timer.start()

	background_manager.transition_to_next_location()
	wave_count += 1
	if wave_count - 1 >= map.size() - 1:
		generate_map(10)
	current_location_index = map[wave_count - 1]
	next_location_index = map[wave_count]

func start_next_wave() -> void:
	set_wave_finished(false)
	set_player(true)
	spawner.set_ready_to_spawn(true)
	prepare_next_location()

func setup_map() -> void:
	# for i in range(3):
	# 	map.append(0)
	generate_map(10)
	current_location_index = map[0]
	next_location_index = map[1]
	background_manager.set_current_location(locations[current_location_index])
	background_manager.set_next_location(locations[next_location_index])
	background_manager.update_textures()

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
	print("Map: ", map)

func prepare_next_location() -> void:
	background_manager.set_next_location(locations[next_location_index])
	background_manager.update_textures()

func get_current_location() -> LocationData:
	return locations[current_location_index]

func update_player_health_label() -> void:
	var health: float
	if player_health:
		health = player_health.get_health()
	else:
		health = 0
	label_manager.update_health_label(health)

func set_player(value: bool) -> void:
	player.set_process(value)
	player.get_attack_controler().set_process(value)
	# player.visible = value
	if value == false:
		player.direction = Vector2.ZERO
	player_attack_controler.set_process(value)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func get_difficulty() -> float:
	return difficulty

func set_difficulty(new_difficulty: float) -> void:
	difficulty = new_difficulty

func add_difficulty(value: float) -> void:
	difficulty += value

func inc_esaped() -> void:
	escaped += 1

func increment_wave_count() -> void:
	wave_count += 1

func get_wave_count() -> int:
	return wave_count

func set_wave_finished(value: bool) -> void:
	wave_finished = value

func get_wave_finished() -> bool:
	return wave_finished

func get_ui_manager() -> UIManager:
	return ui_manager

func get_score() -> float:
	return score

func get_running() -> bool:
	return is_running

func get_spawn_timer_time() -> float:
	return spawner.spawn_timer.time_left

func get_shop_timer_time() -> float:
	return shop_manager.shop_timer.time_left

func get_escaped() -> int:
	return escaped

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		reload_scene()
	if event.is_action_pressed("attack") and not is_running and is_player_alive:
		start_game()

# func toggle_debug_panel() -> void:
# 	if debug_panel.is_open:
# 		debug_panel.move_close()
# 		print("Closed debug panel")
# 	else:
# 		debug_panel.move_open()
# 		print("Opened debug panel")

func _on_player_player_damage_taken() -> void:
	update_player_health_label()

func _on_player_player_died() ->  void:
	is_running = false
	is_player_alive = false
	label_manager.show_end_game_labels()

func _on_enemy_died(points: float, xp: float) -> void:
	score += points
	experience += int(xp)
	ui_manager.update_experience_bar(experience)
	label_manager.update_score_label(score)
	check_level_up()
	# print(points, " ", xp)

func level_up(levels: int) -> void:
	if not levels:
		levels = 1
	for i in range(levels):
		ui_manager.update_experience_bar(experience)
		print("Level up to level: ", level)
		toggle_pause()
		shop_manager.show_shop()
		player.set_is_attacking(false)

func check_level_up() -> void:
	if experience >= experience_needed:
		experience -= experience_needed
		experience_needed = int(experience_needed * experience_needed_modifier)
		level += 1
		ui_manager.update_experience_bar(experience)
		ui_manager.extend_experience_bar(experience_needed)
		print("Level up to level: ", level)
		toggle_pause()
		shop_manager.show_shop()
		player.set_is_attacking(false)
		# spawner.kill_all_enemies()
		# finish_wave()
		# set_player(false)

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state

func reload_scene() -> void:
	if get_tree():
		get_tree().reload_current_scene()

func _on_wave_cooldown_timer_timeout() -> void:
	if not is_running or not wave_finished:
		return
	# Cooldown between waves passed, start the next wave
	start_next_wave()
