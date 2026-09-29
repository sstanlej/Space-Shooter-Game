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
	
	# if location_manager:
	# 	location_manager.set_parallax_active(false)

	if camera_frame:
		camera_frame.move_to_menu_view()

	if intro_sequence:
		intro_sequence.reset_intro()

	if player:
		# Gracz schowany za Ziemią lub wyłączony
		player.visible = false
		player.is_in_game = false

	if campaign_manager and location_manager:
		var initial_loc = campaign_manager.get_current_location()
		if initial_loc:
			location_manager.set_initial_location(initial_loc)

	if ui_manager and ui_manager.has_method("show_notification"):
		ui_manager.show_notification("[color=crimson]SPACE SHOOTER[/color]", "[color=gray]PRESS [/color][color=gold][SPACE][/color][color=gray] TO ESCAPE[/color]", 0.0)
# --- GAME RUN & WAVE FLOW ---

func start_game() -> void:
	is_player_alive = true
	change_state(GameState.TRANSITIONING)

	if ui_manager and ui_manager.has_method("hide_notification"):
		ui_manager.hide_notification(0.2)

	# --- KROK 1: ZAPOWIEDŹ KATASTROFY ---
	# Lekkie drżenie ekranu przed uderzeniem
	if camera_frame and camera_frame.has_method("shake"):
		camera_frame.shake(1.5, 2) # mały wstrząs ostrzegawczy

	# Asteroida rusza z góry
	if intro_sequence:
		intro_sequence.launch_asteroid()

	# --- KROK 2: WYJŚCIE RAKIETY TUŻ PRZED KOLIZJĄ ---
	# Czekamy np. 0.7s, gdy asteroida jest już blisko Ziemi
	await get_tree().create_timer(0.7).timeout
	
	if player and intro_sequence:
		player.global_position = intro_sequence.earth_sprite.global_position
		player.visible = true
		
		# Włączenie efektu silnika startowego

		if player.get_node_or_null("PlayerVisualsComponent").has_method("activate_liftoff_trail"): 
			player.get_node_or_null("PlayerVisualsComponent").activate_liftoff_trail()

		# Rakieta wystrzeliwuje w prawo z lekkim przyspieszeniem
		var target_player_x = camera_frame.get_game_view_player_x() # lub stała pozycja, np. 140.0
		var player_tween = create_tween()
		player_tween.tween_property(player, "global_position:x", target_player_x, 1.1)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# --- KROK 3: UDERZENIE I WYBUCH ---
	# Czekamy na sygnał uderzenia z IntroSequence
	if intro_sequence:
		await intro_sequence.asteroid_impacted

	# Potężny screen shake
	if camera_frame and camera_frame.has_method("shake"):
		camera_frame.shake(12.0, 1.5) # silny wstrząs

	# Dajemy graczowi 0.5s na nacieszenie oka eksplozją Ziemi
	await get_tree().create_timer(1.5).timeout

	# --- KROK 4: KAMERA DOGANIA GRACZA I PRZEJŚCIE DO GRY ---
	if camera_frame:
		camera_frame.move_to_game_view() # płynny ruch kamery w prawo

	# Wyłączamy dym startowy gracza
	if player:
		var trail = player.get_node_or_null("LaunchThrusterTrail") as CPUParticles2D
		if trail: trail.emitting = false
		player.is_in_game = true

	# Start paralaksy i HUD
	# if location_manager:
	# 	location_manager.set_parallax_active(true)

	if ui_manager and ui_manager.has_method("show_hud"):
		ui_manager.show_hud()

	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()

	start_wave()

func start_wave() -> void:
	var wave_def: WaveDefinition = campaign_manager.get_current_wave_definition() if campaign_manager else null
	var current_loc: LocationData = campaign_manager.get_current_location() if campaign_manager else null
	var current_wave = campaign_manager.current_wave if campaign_manager else 1

	if ui_manager:
		if ui_manager.has_method("fade_in_label"): 
			ui_manager.fade_in_label(ui_manager.enemies_left_label, ui_manager.enemies_label_tween, 0.5)

		if ui_manager.has_method("hide_controls_prompt"):
			ui_manager.hide_controls_prompt()

		if ui_manager.has_method("show_hud"): 
			ui_manager.show_hud()

		if wave_def and ui_manager.has_method("show_notification"):
			if wave_def.banner_title != "":
				# Baner zdefiniowany w fali (zastępuje dawny Hazard/Event)
				ui_manager.show_notification(wave_def.banner_title, wave_def.banner_subtitle, 2.2)
			elif wave_def.boss_scene != null and wave_def.enemy_count <= 0:
				# Czysta walka z bossem
				var b_name = wave_def.boss_enemy_data.enemy_name if wave_def.boss_enemy_data else "BOSS"
				ui_manager.show_notification("[color=red]BOSS BATTLE[/color]", "[color=gold]" + b_name + "[/color]", 2.0)
			else:
				# Zwykła fala
				var loc_name = current_loc.location_name if current_loc else "Sector"
				ui_manager.show_notification("[color=gold]WAVE " + str(current_wave) + "[/color]", "[color=gray]" + loc_name + "[/color]", 1.2)

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

	var points: int = progression_manager.get_upgrade_points() if progression_manager else 0
	var is_fully_maxed = false
	if shop_manager and player:
		is_fully_maxed = not shop_manager.has_available_upgrades(player)

	if ui_manager:
		if ui_manager.has_method("update_shop_controls_display"):
			ui_manager.update_shop_controls_display(points, is_fully_maxed)

		if ui_manager.has_method("show_notification"):
			var subtitle = "Press [color=gold][B][/color] to open the SHOP!" if points > 0 else ""
			if is_act_final:
				ui_manager.show_notification("[color=gold]" + act_name.to_upper() + " CLEARED![/color]", subtitle, 2.5)
			else:
				ui_manager.show_notification("[color=gold]WAVE FINISHED![/color]", subtitle, 1.5)

		if ui_manager.has_method("fade_out_label"):
			ui_manager.fade_out_label(ui_manager.enemies_left_label, ui_manager.enemies_label_tween, 0.5)

		if ui_manager.has_method("show_controls_prompt"):
			ui_manager.show_controls_prompt()

	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()

	if campaign_manager and location_manager:
		var upcoming_loc = campaign_manager.get_upcoming_location()
		var current_loc = campaign_manager.get_current_location()
		if upcoming_loc and upcoming_loc != current_loc:
			location_manager.transition_to_location(upcoming_loc)

	if wave_cooldown_timer:
		wave_cooldown_timer.start()

func start_next_wave() -> void:
	if campaign_manager:
		campaign_manager.advance_wave()
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
			
			var points: int = progression_manager.get_upgrade_points() if progression_manager else 0
			var is_fully_maxed = false
			if shop_manager and player:
				is_fully_maxed = not shop_manager.has_available_upgrades(player)

			if ui_manager and ui_manager.has_method("update_shop_controls_display"):
				ui_manager.update_shop_controls_display(points, is_fully_maxed)

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
	var current_wave = campaign_manager.current_wave if campaign_manager else 1
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
