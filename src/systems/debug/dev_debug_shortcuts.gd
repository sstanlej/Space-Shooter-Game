class_name DevDebugShortcuts extends Node

var god_mode: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return

	match event.keycode:
		KEY_F1:
			level_up()
		KEY_F2:
			handle_wave_skip()
		KEY_F3:
			toggle_god_mode()
		KEY_F4:
			toggle_spectator_mode()

func level_up() -> void:
	var progression: ProgressionManager = get_progression_manager()
	if not progression:
		return

	var needed_xp: int = progression.experience_needed - progression.experience
	progression.add_experience(maxi(1, needed_xp))

	var ui: UIManager = get_ui_manager()
	if ui and ui.shop_ui and ui.shop_ui.visible:
		ui.shop_ui.update_upgrades_available_display()

	show_debug_notification("DEBUG: LEVEL UP! (LVL %d)" % progression.get_level())

# --- F2: SKIP FALI / PRZEJŚCIA ---

func handle_wave_skip() -> void:
	var gm = get_game_manager()
	if not gm:
		return

	if gm.current_state == GameManager.GameState.IN_WAVE:
		clear_all_enemies()
		show_debug_notification("SKIPPING WAVE")
		gm.finish_wave()
	elif gm.current_state == GameManager.GameState.BETWEEN_WAVES:
		if gm.wave_cooldown_timer:
			gm.wave_cooldown_timer.stop()
		show_debug_notification("STARTING NEXT WAVE")
		gm.start_next_wave()

# --- F3: GOD MODE (TOGGLE) ---

func toggle_god_mode() -> void:
	god_mode = !god_mode
	var player = get_player()

	if player:
		if player.health_component and "is_invincible" in player.health_component:
			player.health_component.is_invincible = god_mode

		if god_mode:
			player.modulate = Color(1.5, 1.5, 0.5, 1.0)
			show_debug_notification("GODMODE: ON")
		else:
			player.modulate = Color.WHITE
			show_debug_notification("GODMODE: OFF")

# --- F4: SPECTATOR MODE (TOGGLE) ---

func toggle_spectator_mode() -> void:
	var player = get_player()
	if player and player.has_method("toggle_spectator_mode"):
		var is_active = player.toggle_spectator_mode()
		show_debug_notification("SPECTATOR MODE: %s" % ("ON" if is_active else "OFF"))

# --- POMOCNICZE ---

func clear_all_enemies() -> void:
	var root_children = get_tree().root.find_children("*", "", true, false)
	for node in root_children:
		if node is Enemy and is_instance_valid(node):
			node.queue_free()

func show_debug_notification(text: String) -> void:
	print("[Debug] " + text)
	var ui = get_ui_manager()
	if ui and ui.has_method("show_notification"):
		ui.show_notification("[color=gold]DEBUG[/color]", "[color=white]" + text + "[/color]", 1.2)

func get_game_manager() -> GameManager:
	for node in get_tree().root.find_children("*", "", true, false):
		if node is GameManager:
			return node
	return null

func get_ui_manager() -> UIManager:
	for node in get_tree().root.find_children("*", "", true, false):
		if node is UIManager:
			return node
	return null

func get_progression_manager() -> ProgressionManager:
	for node in get_tree().root.find_children("*", "", true, false):
		if node is ProgressionManager:
			return node
	return null

func get_player() -> Player:
	for node in get_tree().root.find_children("*", "", true, false):
		if node is Player:
			return node
	return null
