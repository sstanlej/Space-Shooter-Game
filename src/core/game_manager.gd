class_name GameManager extends Node

enum GameState {
	WAIT_TO_START,
	TRANSITIONING,
	IN_WAVE,
	BETWEEN_WAVES,
	IN_SHOP,
	DECK_OVERVIEW,
	PAUSED,
	GAME_OVER
}

signal state_changed(old_state: GameState, new_state: GameState)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)

var current_state: GameState = GameState.WAIT_TO_START
var state_before_pause: GameState = GameState.IN_WAVE
var is_player_alive: bool = true

@export_group("World & Physics Control")
@export var world: Node2D

@export_group("System Managers")
@export var campaign_manager: CampaignManager
@export var location_manager: LocationManager
@export var progression_manager: ProgressionManager
@export var spawner: Spawner
@export var ui_manager: UIManager
@export var shop_ui: ShopUI
@export var shop_manager: ShopManager
@export var deck_overview_ui: DeckOverviewUI

@export_group("Scene References")
@export var player: Player
@export var camera_frame: CameraFrame
@export var wave_cooldown_timer: Timer

@export_group("Intro Scene References")
@export var intro_sequence: IntroSequence
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_connect_timer_signals()
	_connect_player_signals()
	_connect_spawner_signals()
	_connect_deck_signals()
	wait_to_start()

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GameState.WAIT_TO_START and is_player_alive:
		if event.is_action_pressed("attack"):
			start_game()

	elif current_state == GameState.BETWEEN_WAVES:
		if event.is_action_pressed("shop"):
			open_shop()
		elif event.is_action_pressed("deck_overview"):
			open_deck_overview()

	elif current_state == GameState.DECK_OVERVIEW:
		if event.is_action_pressed("deck_overview") or event.is_action_pressed("pause"):
			close_deck_overview()

	if event.is_action_pressed("pause"):
		if current_state in [GameState.IN_WAVE, GameState.BETWEEN_WAVES, GameState.PAUSED]:
			toggle_pause()

	if event.is_action_pressed("reset"):
		reload_scene()

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

	match current_state:
		GameState.WAIT_TO_START:
			set_world_paused(true)
			set_player_input_enabled(false)

		GameState.TRANSITIONING:
			set_world_paused(false)
			set_player_input_enabled(false)

		GameState.IN_WAVE:
			set_world_paused(false)
			set_player_input_enabled(true)

		GameState.BETWEEN_WAVES:
			set_world_paused(false)
			set_player_input_enabled(true)
			_resume_cooldown_timer()

		GameState.IN_SHOP:
			set_world_paused(true)
			_pause_cooldown_timer()

		GameState.DECK_OVERVIEW:
			set_world_paused(true)
			set_player_input_enabled(false)
			_pause_cooldown_timer()

		GameState.PAUSED:
			set_world_paused(true)

		GameState.GAME_OVER:
			set_player_input_enabled(false)

func set_world_paused(paused: bool) -> void:
	if world:
		world.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT

func wait_to_start() -> void:
	change_state(GameState.WAIT_TO_START)

	if camera_frame:
		camera_frame.move_to_menu_view()

	if intro_sequence:
		intro_sequence.reset_intro()

	_setup_player_for_menu()
	_setup_initial_location()

	if ui_manager:
		ui_manager.show_start_prompt()

func start_game() -> void:
	is_player_alive = true
	change_state(GameState.TRANSITIONING)

	if ui_manager:
		ui_manager.prepare_for_game_start()

	if intro_sequence:
		intro_sequence.play_sequence()
		await intro_sequence.sequence_finished

	_initialize_game_run()
	start_wave()

func start_wave() -> void:
	var wave_def = campaign_manager.get_current_wave_definition() if campaign_manager else null
	var current_loc = campaign_manager.get_current_location() if campaign_manager else null
	var current_wave = campaign_manager.current_wave if campaign_manager else 1

	if ui_manager:
		ui_manager.show_wave_start(current_wave, wave_def, current_loc)

	change_state(GameState.IN_WAVE)
	wave_started.emit(current_wave)

	if spawner and wave_def:
		spawner.start_spawning_wave(wave_def)

func finish_wave() -> void:
	var current_wave = campaign_manager.current_wave if campaign_manager else 1
	var is_act_final = campaign_manager.is_current_wave_last_in_act() if campaign_manager else false
	var act_name = campaign_manager.get_current_act_data().act_name if campaign_manager and campaign_manager.get_current_act_data() else ""

	print("[GameManager] Wave %d finished successfully.\n" % current_wave)
	if is_act_final:
		print("[GameManager] *** %s COMPLETED! ***\n" % act_name.to_upper())

	wave_ended.emit(current_wave)
	change_state(GameState.BETWEEN_WAVES)

	var points = progression_manager.get_upgrade_points() if progression_manager else 0
	var is_maxed = not shop_manager.has_available_upgrades(player) if (shop_manager and player) else false

	if ui_manager:
		ui_manager.show_wave_finished(is_act_final, act_name, points, is_maxed)

	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()

	_check_upcoming_location_transition()

	if wave_cooldown_timer:
		wave_cooldown_timer.start()

func start_next_wave() -> void:
	if campaign_manager:
		campaign_manager.advance_wave()
	start_wave()

func open_shop() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		change_state(GameState.IN_SHOP)
		if ui_manager:
			ui_manager.hide_controls_prompt()
		if shop_ui and shop_ui.has_method("show_shop"):
			shop_ui.show_shop()

func close_shop() -> void:
	if current_state == GameState.IN_SHOP:
		if shop_ui and shop_ui.has_method("hide_shop"):
			await shop_ui.hide_shop()
			_refresh_shop_controls()
		change_state(GameState.BETWEEN_WAVES)

func open_deck_overview() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		change_state(GameState.DECK_OVERVIEW)
		if deck_overview_ui:
			deck_overview_ui.show_overview()

func close_deck_overview() -> void:
	if current_state == GameState.DECK_OVERVIEW:
		if deck_overview_ui:
			deck_overview_ui.close_overview()

func toggle_pause() -> void:
	if current_state != GameState.PAUSED:
		state_before_pause = current_state
		_pause_cooldown_timer()
		if spawner and spawner.has_method("pause_timers"):
			spawner.pause_timers(true)

		change_state(GameState.PAUSED)
		if ui_manager:
			ui_manager.show_pause_state(true)

	elif current_state == GameState.PAUSED:
		change_state(state_before_pause)
		if state_before_pause == GameState.BETWEEN_WAVES:
			_resume_cooldown_timer()
		if spawner and spawner.has_method("pause_timers"):
			spawner.pause_timers(false)
		if ui_manager:
			ui_manager.show_pause_state(false)

func game_over() -> void:
	is_player_alive = false
	var current_wave = campaign_manager.current_wave if campaign_manager else 1
	print("\n[GameManager] GAME OVER! Player eliminated at Wave %d.\n" % current_wave)

	change_state(GameState.GAME_OVER)
	if spawner and spawner.has_method("pause_timers"):
		spawner.pause_timers(true)

	var score = progression_manager.get_score() if progression_manager else 0.0
	var distance = progression_manager.get_distance() if progression_manager else 0.0

	if ui_manager:
		ui_manager.show_game_over(current_wave, score, distance)

func reload_scene() -> void:
	get_tree().reload_current_scene()

func set_player_input_enabled(enabled: bool) -> void:
	if player:
		player.is_in_game = enabled
		player.set_process(enabled)
		player.set_physics_process(enabled)
		if player.get("attack_controller"):
			player.attack_controller.set_process(enabled)

func _setup_player_for_menu() -> void:
	if player:
		player.visible = false
		player.is_in_game = false

func _setup_initial_location() -> void:
	if campaign_manager and location_manager:
		var initial_loc = campaign_manager.get_current_location()
		if initial_loc:
			location_manager.set_initial_location(initial_loc)

func _initialize_game_run() -> void:
	if ui_manager:
		ui_manager.show_hud()
		if player and player.health_component:
			var player_hc = player.health_component
			var max_hp = int(player_hc.get_max_health()) if player_hc.has_method("get_max_health") else 3
			var current_hp = int(player_hc.get_health()) if player_hc.has_method("get_health") else 3
			ui_manager.setup_health_bar(max_hp, current_hp)

	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()

func _refresh_shop_controls() -> void:
	var points = progression_manager.get_upgrade_points() if progression_manager else 0
	var is_maxed = not shop_manager.has_available_upgrades(player) if (shop_manager and player) else false

	if ui_manager:
		ui_manager.update_shop_controls_display(points, is_maxed)
		ui_manager.show_controls_prompt()

func _check_upcoming_location_transition() -> void:
	if campaign_manager and location_manager:
		var upcoming_loc = campaign_manager.get_upcoming_location()
		var current_loc = campaign_manager.get_current_location()
		if upcoming_loc and upcoming_loc != current_loc:
			location_manager.transition_to_location(upcoming_loc)

func _pause_cooldown_timer() -> void:
	if wave_cooldown_timer and not wave_cooldown_timer.is_stopped():
		wave_cooldown_timer.paused = true

func _resume_cooldown_timer() -> void:
	if wave_cooldown_timer and wave_cooldown_timer.is_paused():
		wave_cooldown_timer.paused = false

func _connect_timer_signals() -> void:
	if wave_cooldown_timer:
		wave_cooldown_timer.timeout.connect(_on_wave_cooldown_timer_timeout)

func _connect_player_signals() -> void:
	if not player:
		return
	if player.has_signal("player_damage_taken"):
		player.player_damage_taken.connect(_on_player_damage_taken)
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if player.get("attack_controller") and spawner:
		player.attack_controller.projectiles_container = spawner.projectiles_container
	if player.health_component:
		player.health_component.health_changed.connect(func(cur, mx): ui_manager.update_health_bar(cur, mx))

func _connect_spawner_signals() -> void:
	if spawner and spawner.has_signal("wave_completed"):
		spawner.wave_completed.connect(finish_wave)

func _connect_deck_signals() -> void:
	if deck_overview_ui:
		deck_overview_ui.deck_overview_closed.connect(_on_deck_overview_closed)

func _on_wave_cooldown_timer_timeout() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		start_next_wave()

func _on_player_died() -> void:
	if camera_frame:
		camera_frame.shake(5, 2)
	GlobalAudio.play_long_explosion()
	game_over()

func _on_player_damage_taken() -> void:
	if camera_frame:
		camera_frame.shake(5.0, 0.3)

func _on_deck_overview_closed() -> void:
	change_state(GameState.BETWEEN_WAVES)