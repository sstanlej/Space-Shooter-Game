class_name GameManager extends Node

# --- Maszyna Stanów ---
enum GameState {
	WAIT_TO_START, # Czekanie na wciśnięcie startu w menu/ekranie początkowym
	TRANSITIONING, # Animacja początku gry przed pierwszą falą
	IN_WAVE,       # Trwa fala: świat gry działa, wrogowie się spawnują
	BETWEEN_WAVES, # Przerwa między falami: odliczanie, płynna zmiana lokacji w tle
	IN_SHOP,       # Świat gry zamrożony, otwarte okno sklepu
	PAUSED,        # Zwykła pauza gry
	GAME_OVER      # Gracz przegrał (świat gry zamrożony)
}

# --- Sygnały Zmiany Stanu ---
signal state_changed(old_state: GameState, new_state: GameState)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)

# --- Zmienne Rozgrywki ---
var current_state: GameState = GameState.WAIT_TO_START
var state_before_pause: GameState = GameState.IN_WAVE
var current_wave: int = 1
var is_player_alive: bool = true

# --- Referencja do Świata Gry (Nowy System Pauzy!) ---
@export_group("World & Physics Control")
@export var world: Node2D # Węzeł World zawierający gracza, wrogów, pociski i tło

# --- Referencje do Pozostałych Managerów ---
@export_group("System Managers")
@export var location_manager: LocationManager
@export var progression_manager: ProgressionManager
@export var spawner: Spawner # Nasz przyszły Spawner / Director
@export var ui_manager: UIManager
@export var shop_ui: ShopUI

@export_group("Scene References")
@export var player: Player
@export var camera_frame: CameraFrame
@export var wave_cooldown_timer: Timer

func _ready() -> void:
	if wave_cooldown_timer:
		wave_cooldown_timer.timeout.connect(_on_wave_cooldown_timer_timeout)

	if player:
		if player.has_signal("player_damage_taken"):
			player.player_damage_taken.connect(_on_player_damage_taken)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		if player.get("attack_controler") and spawner:
			player.attack_controler.projectiles_container = spawner.projectiles_container

	if spawner:
		if spawner.has_signal("wave_completed"):
			spawner.wave_completed.connect(finish_wave)
	# Wejście w stan początkowy
	wait_to_start()

func _unhandled_input(event: InputEvent) -> void:
	# Start gry po wciśnięciu przycisku ataku na ekranie startowym
	if current_state == GameState.WAIT_TO_START and is_player_alive:
		if event.is_action_pressed("attack"):
			start_game()

	# Otwieranie sklepu w trakcie przerwy między falami (klawisz 'shop' / np. 'B')
	elif current_state == GameState.BETWEEN_WAVES:
		if event.is_action_pressed("shop"):
			open_shop()

	# Zwykła pauza (ESC / P)
	if event.is_action_pressed("pause"):
		if current_state == GameState.IN_WAVE or current_state == GameState.BETWEEN_WAVES or current_state == GameState.PAUSED:
			toggle_pause()

	# Reset sceny (Debug / Quick Restart)
	if event.is_action_pressed("reset"):
		reload_scene()

# --- Główna Logika Maszyny Stanów z Pauzowaniem Węzła World ---
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
			print("[GameManager] Stan: WAIT_TO_START")

		GameState.TRANSITIONING:
			set_world_paused(false) # Świat gry działa (tło płynie), gracz może latać
			set_player_input_enabled(false)
			print("[GameManager] Stan: TRANSITIONING")

		GameState.IN_WAVE:
			set_world_paused(false) # Świat gry działa!
			set_player_input_enabled(true)
			print("[GameManager] Stan: IN_WAVE (Fala: ", current_wave, ")")

		GameState.BETWEEN_WAVES:
			set_world_paused(false) # Świat gry działa (tło płynie), gracz może latać
			set_player_input_enabled(true)
			print("[GameManager] Stan: BETWEEN_WAVES")

		GameState.IN_SHOP:
			set_world_paused(true) # ZAMRAŻAMY ŚWIAT GRY na czas Sklepu!
			print("[GameManager] Stan: IN_SHOP")

		GameState.PAUSED:
			set_world_paused(true) # ZAMRAŻAMY ŚWIAT GRY na czas Pauzy!
			print("[GameManager] Stan: PAUSED")

		GameState.GAME_OVER:
			set_player_input_enabled(false)
			print("[GameManager] Stan: GAME_OVER")

# --- Funkcja Pomocnicza do Pauzowania Świata ---
func set_world_paused(paused: bool) -> void:
	if world:
		if paused:
			world.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			world.process_mode = Node.PROCESS_MODE_INHERIT

# --- Kontrola Przebiegu Gry ---

func wait_to_start() -> void:
	change_state(GameState.WAIT_TO_START)
	if camera_frame:
		camera_frame.move_to_menu_view()

	if ui_manager and ui_manager.has_method("show_notification"):
		ui_manager.show_notification("[color=red]SPACE SHOOTER[/color]", "[color=gray]PRESS [/color][color=gold][SPACE][/color][color=gray] TO START[/color]", 0.0)

func start_game() -> void:
	is_player_alive = true
	current_wave = 1
	change_state(GameState.TRANSITIONING)

	if ui_manager and ui_manager.has_method("hide_notification"):
		ui_manager.hide_notification(0.4)

	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()

	if ui_manager:
		if ui_manager.has_method("show_hud"): ui_manager.show_hud()
		if player and player.has_method("get_health_component"):
			var player_hc = player.get_health_component()
			var max_hp = int(player_hc.get_max_health()) if player_hc.has_method("get_max_health") else 100
			var current_hp = int(player_hc.get_health())

			ui_manager.setup_health_bar(max_hp, current_hp)

			var player_damage: int = int(player.get_attack_controler().get_damage())
			var player_attack_speed: int = int(player.get_attack_controler().get_attack_speed())
			var player_speed: int = int(player.get_movement_speed())
			ui_manager.update_stats_label(player_damage, player_speed, player_attack_speed)

	await play_start_animation()
	start_wave()

func finish_wave() -> void:
	wave_ended.emit(current_wave)
	change_state(GameState.BETWEEN_WAVES)

	if ui_manager and ui_manager.has_method("show_notification"):
		var points: int = 0
		if progression_manager and progression_manager.has_method("get_upgrade_points"):
			points = progression_manager.get_upgrade_points()

		var subtitle_text: String = ""
		if points > 0:
			subtitle_text = "[color=gray]Spend [/color][color=gold]" + str(points) + "[/color][color=gray] upgrade point(s) in the Shop! [/color][color=gold][B][/color]"
		else:
			subtitle_text = "[color=gray]Press [/color][color=gold][B][/color][color=gray] to open Shop![/color]"

		ui_manager.show_notification("[color=gold]WAVE FINISHED![/color]", subtitle_text, 1.5)

	if ui_manager.has_method("hide_enemies_left_label"):
		ui_manager.hide_enemies_left_label(0.5)

	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()

	if location_manager and location_manager.has_method("transition_to_next_location"):
		location_manager.advance_to_wave(current_wave + 1)
		location_manager.transition_to_next_location()

	if wave_cooldown_timer:
		wave_cooldown_timer.start()

func play_start_animation() -> void:
	var camera_tween
	var player_tween

	if camera_frame:
		camera_tween = camera_frame.move_to_game_view()
	if player:
		player_tween = player.move_to_game_view()

	if player_tween:
		await player_tween.finished

func start_wave() -> void:
	if ui_manager:
		if ui_manager.has_method("hide_start_game_label"): ui_manager.hide_start_game_label()
		if ui_manager.has_method("show_hud"): ui_manager.show_hud()
		if ui_manager.has_method("show_enemies_left_label"): ui_manager.show_enemies_left_label(0.5)
		if ui_manager.has_method("show_notification"):
			ui_manager.show_notification("[color=gold]WAVE " + str(current_wave) + "[/color]", "[color=gray]Shoot them up![/color]", 1.0)
	change_state(GameState.IN_WAVE)
	wave_started.emit(current_wave)

	if spawner and spawner.has_method("start_spawning"):
		spawner.start_spawning()

func start_next_wave() -> void:
	current_wave += 1
	start_wave()

# --- Sklep i Pauza ---

func open_shop() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		change_state(GameState.IN_SHOP)
		if shop_ui and shop_ui.has_method("show_shop"):
			shop_ui.show_shop()

func close_shop() -> void:
	if current_state == GameState.IN_SHOP:
		if shop_ui and shop_ui.has_method("hide_shop"):
			await shop_ui.hide_shop()
		change_state(GameState.BETWEEN_WAVES)

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

		if wave_cooldown_timer:
			wave_cooldown_timer.paused = false

		if spawner and spawner.has_method("pause_timers"):
			spawner.pause_timers(false)

		if ui_manager and ui_manager.has_method("hide_notification"):
			ui_manager.hide_notification(0.4)

func game_over() -> void:
	is_player_alive = false
	change_state(GameState.GAME_OVER)

	if ui_manager and ui_manager.has_method("hide_enemies_left_label"):
		ui_manager.hide_enemies_left_label(0.3)

	if spawner and spawner.has_method("pause_timers"):
		spawner.pause_timers(true)

	if ui_manager:
		var score: float = 0.0
		var distance: float = 0.0
		ui_manager.hide_hud()

		if progression_manager:
			if progression_manager.get("score"): score = progression_manager.get_score()
			if progression_manager.get("distance"): distance = progression_manager.get_distance()

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
		player.set_process(enabled)
		player.set_physics_process(enabled)
		if player.get("attack_controler"):
			player.attack_controler.set_process(enabled)

# --- Sygnały i Timery ---

func _on_wave_cooldown_timer_timeout() -> void:
	if current_state == GameState.BETWEEN_WAVES:
		start_next_wave()

func _on_player_died() -> void:
	game_over()

func _on_player_damage_taken() -> void:
	if ui_manager and player:
		var current_hp = int(player.get_health_component().get_health())
		ui_manager.update_health_bar(current_hp)
