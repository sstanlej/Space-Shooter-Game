class_name DevDebugShortcuts extends Node

var god_mode: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return

	match event.keycode:
		KEY_F1:
			toggle_god_mode()
		KEY_F2:
			handle_wave_skip()
		KEY_F3:
			add_upgrade_point()

# --- F1: GOD MODE ---

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
	else:
		print("[Debug Error] Nie znaleziono węzła Player!")

# --- F2: SKIP FALI / OKRESU PRZEJŚCIOWEGO ---

func handle_wave_skip() -> void:
	var gm = get_game_manager()
	if not gm:
		print("[Debug Error] Nie znaleziono GameManager!")
		return

	# 1. Trwa fala -> niszczymy wrogów i przechodzimy do przerwy między falami
	if gm.current_state == GameManager.GameState.IN_WAVE:
		clear_all_enemies()
		show_debug_notification("SKIPPING WAVE")
		gm.finish_wave()

	# 2. Przerwa między falami -> przerywamy timer i natychmiast odpalamy kolejną falę
	elif gm.current_state == GameManager.GameState.BETWEEN_WAVES:
		if gm.wave_cooldown_timer:
			gm.wave_cooldown_timer.stop()
		show_debug_notification("STARTING NEXT WAVE")
		gm.start_next_wave()

# --- F3: +1 PUNKT ULEPSZENIA ---

func add_upgrade_point() -> void:
	var progression = get_progression_manager()
	var current_points: int = 0

	if progression:
		if progression.has_method("add_upgrade_points"):
			progression.add_upgrade_points(1)
		elif "upgrade_points" in progression:
			progression.upgrade_points += 1

		if progression.has_method("get_upgrade_points"):
			current_points = progression.get_upgrade_points()
		elif "upgrade_points" in progression:
			current_points = progression.upgrade_points

		show_debug_notification("+1 UPGRADE POINT (%d)" % current_points)
	else:
		print("[Debug Error] Nie znaleziono ProgressionManager!")

# --- CZYSZCZENIE PRZECIWNIKÓW I POWIADOMIENIA ---

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

# --- DYNAMICZNE WYSZUKIWANIE PO KLASACH GDSCRIPT ---

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