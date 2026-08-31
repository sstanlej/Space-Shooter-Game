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
var current_wave: int = 1
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

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if wave_cooldown_timer:
		wave_cooldown_timer.timeout.connect(_on_wave_cooldown_timer_timeout)

	if player:
		if player.has_signal("player_damage_taken"):
			player.player_damage_taken.connect(_on_player_damage_taken)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		if player.get("attack_controller") and spawner:
			player.attack_controller.projectiles_container = spawner.projectiles_container

		if player.health_component:
			player.health_component.health_changed.connect(func(cur, mx): ui_manager.update_health_bar(cur, mx))

	if spawner:
		if spawner.has_signal("wave_completed"):
			spawner.wave_completed.connect(finish_wave)

	if deck_overview_ui:
		deck_overview_ui.deck_overview_closed.connect(_on_deck_overview_closed)

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

# --- STATE MANAGEMENT ---

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
			if wave_cooldown_timer and wave_cooldown_timer.is_paused():
				wave_cooldown_timer.paused = false

		GameState.IN_SHOP:
			set_world_paused(true)
			if wave_cooldown_timer and not wave_cooldown_timer.is_stopped():
				wave_cooldown_timer.paused = true

		GameState.DECK_OVERVIEW:
			set_world_paused(true)
			set_player_input_enabled(false)
			if wave_cooldown_timer and not wave_cooldown_timer.is_stopped():
				wave_cooldown_timer.paused = true

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
	if ui_manager and ui_manager.has_method("show_notification"):
		ui_manager.show_notification("[color=red]SPACE SHOOTER[/color]", "[color=gray]PRESS [/color][color=gold][SPACE][/color][color=gray] TO START[/color]", 0.0)

# --- GAME RUN & WAVE FLOW ---

func start_game() -> void:
	print("\n=================== NEW GAME RUN STARTED ===================")
	is_player_alive = true
	current_wave = 1
	change_state(GameState.TRANSITIONING)

	if campaign_manager:
		campaign_manager.reset_campaign()

	if shop_manager and shop_manager.deck_manager:
		shop_manager.deck_manager.reset_deck()

	if ui_manager and ui_manager.has_method("hide_notification"):
		ui_manager.hide_notification(0.4)

	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()

	if player and player.get_deck_component():
		player.get_deck_component().initialize_starting_deck()

	if campaign_manager and location_manager:
		var initial_cfg = campaign_manager.get_wave_config(1)
		if initial_cfg and initial_cfg.location:
			location_manager.set_initial_location(initial_cfg.location)

	if ui_manager:
		if ui_manager.has_method("show_hud"):
			ui_manager.show_hud()
		if player and player.health_component:
			var player_hc = player.health_component
			var max_hp = int(player_hc.get_max_health()) if player_hc.has_method("get_max_health") else 100
			var current_hp = int(player_hc.get_health()) if player_hc.has_method("get_health") else 100
			ui_manager.setup_health_bar(max_hp, current_hp)

	anim_player.play("intro")
	await anim_player.animation_finished
	if player:
		player.is_in_game = true
	start_wave()

func start_wave() -> void:
	var cfg: WaveConfig = campaign_manager.get_wave_config(current_wave) if campaign_manager else null

	if ui_manager:
		if ui_manager.has_method("fade_in_label"): 
			ui_manager.fade_in_label(ui_manager.enemies_left_label, ui_manager.enemies_label_tween, 0.5)

		if ui_manager.has_method("hide_controls_prompt"):
			ui_manager.hide_controls_prompt()

		if ui_manager.has_method("show_hud"): 
			ui_manager.show_hud()

		if cfg and ui_manager.has_method("show_notification"):
			match cfg.wave_type:
				WaveConfig.WaveType.BOSS:
					ui_manager.show_notification("[color=red]BOSS BATTLE[/color]", "[color=gold]Defeat the Boss of " + cfg.act_name + "![/color]", 2.0)
				WaveConfig.WaveType.EVENT:
					var event_name = cfg.event_id.replace("_", " ").to_upper()
					ui_manager.show_notification("[color=crimson]EVENT: " + event_name + "[/color]", "[color=gold]Survive the hazard![/color]", 2.0)
				WaveConfig.WaveType.STANDARD:
					var loc_name = cfg.location.location_name if cfg.location else "Sector"
					ui_manager.show_notification("[color=gold]WAVE " + str(current_wave) + "[/color]", "[color=gray]" + loc_name + "[/color]", 1.2)

	change_state(GameState.IN_WAVE)
	wave_started.emit(current_wave)

	if spawner and cfg:
		spawner.start_spawning_wave(cfg)

func finish_wave() -> void:
	var completed_cfg: WaveConfig = campaign_manager.get_wave_config(current_wave) if campaign_manager else null

	print("[GameManager] Wave %d finished successfully.\n" % current_wave)
	if completed_cfg and completed_cfg.is_act_final:
		print("[GameManager] *** %s COMPLETED! ***\n" % completed_cfg.act_name.to_upper())

	wave_ended.emit(current_wave)
	change_state(GameState.BETWEEN_WAVES)

	var points: int = progression_manager.get_upgrade_points() if progression_manager else 0

	var is_fully_maxed = false
	if shop_manager and player:
		var available_cards = shop_manager.deck_manager.get_cards_for_shop(3, player) if shop_manager.deck_manager else []
		is_fully_maxed = available_cards.is_empty()

	if ui_manager:
		if ui_manager.has_method("update_shop_controls_display"):
			ui_manager.update_shop_controls_display(points, is_fully_maxed)

		if ui_manager.has_method("show_notification"):
			var subtitle = "Press [color=gold][B][/color] to open the SHOP!" if points > 0 else ""
			if completed_cfg and completed_cfg.is_act_final:
				ui_manager.show_notification("[color=gold]" + completed_cfg.act_name.to_upper() + " CLEARED![/color]", subtitle, 2.5)
			else:
				ui_manager.show_notification("[color=gold]WAVE FINISHED![/color]", subtitle, 1.5)

		if ui_manager.has_method("fade_out_label"):
			ui_manager.fade_out_label(ui_manager.enemies_left_label, ui_manager.enemies_label_tween, 0.5)

		if ui_manager.has_method("show_controls_prompt"):
			ui_manager.show_controls_prompt()

	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()

	if campaign_manager and location_manager:
		var next_cfg = campaign_manager.get_wave_config(current_wave + 1)
		if next_cfg and next_cfg.location:
			location_manager.transition_to_location(next_cfg.location)

	if wave_cooldown_timer:
		wave_cooldown_timer.start()

func start_next_wave() -> void:
	current_wave += 1
	start_wave()

# --- SHOP & DECK ---

func open_shop() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		change_state(GameState.IN_SHOP)
		if ui_manager.has_method("hide_controls_prompt"):
			ui_manager.hide_controls_prompt()
		if shop_ui and shop_ui.has_method("show_shop"):
			shop_ui.show_shop()

func close_shop() -> void:
	if current_state == GameState.IN_SHOP:
		if shop_ui and shop_ui.has_method("hide_shop"):
			await shop_ui.hide_shop()
			if ui_manager.has_method("show_controls_prompt"):
				ui_manager.show_controls_prompt()
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

func _on_deck_overview_closed() -> void:
	change_state(GameState.BETWEEN_WAVES)

# --- PAUSE & GAME OVER ---

func toggle_pause() -> void:
	if current_state != GameState.PAUSED:
		state_before_pause = current_state
		if wave_cooldown_timer and not wave_cooldown_timer.is_paused():
			wave_cooldown_timer.paused = true
		if spawner and spawner.has_method("pause_timers"):
			spawner.pause_timers(true)

		change_state(GameState.PAUSED)
		if ui_manager and ui_manager.has_method("show_notification"):
			ui_manager.show_notification("[color=gold]PAUSED[/color]", "[color=gray]Press [/color][color=gold][ESC][/color][color=gray] to Resume[/color]", 0.0)

	elif current_state == GameState.PAUSED:
		change_state(state_before_pause)
		if wave_cooldown_timer and state_before_pause == GameState.BETWEEN_WAVES:
			wave_cooldown_timer.paused = false
		if spawner and spawner.has_method("pause_timers"):
			spawner.pause_timers(false)
		if ui_manager and ui_manager.has_method("hide_notification"):
			ui_manager.hide_notification(0.4)

func game_over() -> void:
	is_player_alive = false
	print("\n[GameManager] GAME OVER! Player eliminated at Wave %d.\n" % current_wave)

	change_state(GameState.GAME_OVER)
	if ui_manager and ui_manager.has_method("hide_enemies_left_label"):
		ui_manager.hide_enemies_left_label(0.3)
	if spawner and spawner.has_method("pause_timers"):
		spawner.pause_timers(true)
	if ui_manager:
		var score: float = progression_manager.get_score() if progression_manager else 0.0
		var distance: float = progression_manager.get_distance() if progression_manager else 0.0
		ui_manager.hide_hud()
		if ui_manager.has_method("update_game_over_stats"):
			ui_manager.update_game_over_stats(current_wave, score, distance)
		if ui_manager.has_method("show_game_over_screen"):
			ui_manager.show_game_over_screen()
		if ui_manager.has_method("show_notification"):
			ui_manager.show_notification("[color=red]GAME OVER[/color]", "[color=gray]Press [/color][color=gold][R][/color][color=gray] to Restart[/color]", 0.0)

func reload_scene() -> void:
	get_tree().reload_current_scene()

func set_player_input_enabled(enabled: bool) -> void:
	if player:
		player.is_in_game = enabled
		player.set_process(enabled)
		player.set_physics_process(enabled)
		if player.get("attack_controller"):
			player.attack_controller.set_process(enabled)

# --- SIGNALS & CALLBACKS ---

func _on_wave_cooldown_timer_timeout() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		start_next_wave()

func _on_player_died() -> void:
	game_over()

func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if ui_manager:
		ui_manager.update_health_bar(current_hp)

func _on_player_damage_taken() -> void:
	pass
