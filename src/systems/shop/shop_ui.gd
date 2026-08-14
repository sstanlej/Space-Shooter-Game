class_name ShopUI extends Control

signal shop_closed

@export_group("System References")
@export var game_manager: GameManager
@export var progression_manager: ProgressionManager
@export var player: Player
@export var deck_manager: CardDeckManager

@export_group("UI Elements")
@export var background_overlay: ColorRect
@export var cards_container: HBoxContainer
@export var card_ui_scene: PackedScene

@export_group("Animation Settings")
@export var transition_duration: float = 0.35

var target_center_x: float = 0.0
var target_center_y: float = 0.0

var active_cards_ui: Array[CardUI] = []
var selected_index: int = 0
var active: bool = false
var tween: Tween

func _ready() -> void:
	if background_overlay:
		background_overlay.modulate.a = 0.0
	hide()

func _on_player_level_up(_new_level: int, _total_points: int) -> void:
	if deck_manager:
		deck_manager.mark_needs_reroll()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("right") and selected_index < active_cards_ui.size() - 1:
		selected_index += 1
		update_selection()

	elif event.is_action_pressed("left") and selected_index > 0:
		selected_index -= 1
		update_selection()

	elif event.is_action_pressed("attack"):
		confirm_selection()

	elif event.is_action_pressed("shop") or event.is_action_pressed("pause"):
		game_manager.close_shop()

func show_shop() -> void:
	if not player and game_manager and game_manager.player:
		player = game_manager.player

	show()
	selected_index = 0
	
	var viewport_size = get_viewport_rect().size
	if cards_container:
		cards_container.position.y = viewport_size.y + 50.0
	
	generate_cards()
	
	await get_tree().process_frame
	calculate_positions()
	
	await animate_open()
	active = true
	update_selection(false)

func hide_shop() -> void:
	active = false
	# Jeśli karty zostały już usunięte po wyborze, ściemniamy tylko tło
	if active_cards_ui.is_empty():
		await fade_out_overlay()
	else:
		await animate_close()
		clear_cards()
		
	hide()
	shop_closed.emit()

func calculate_positions() -> void:
	if not cards_container:
		return
	
	cards_container.reset_size()
	var container_size = cards_container.get_combined_minimum_size()
	var viewport_size = get_viewport_rect().size
	
	target_center_x = (viewport_size.x - container_size.x) / 2.0
	target_center_y = (viewport_size.y - container_size.y) / 2.0
	
	cards_container.position.x = target_center_x
	cards_container.position.y = viewport_size.y + 50.0

func generate_cards() -> void:
	clear_cards()
	if not deck_manager or not card_ui_scene or not cards_container:
		return

	var drawn_cards: Array[UpgradeCardData] = deck_manager.get_cards_for_shop(3, player)
	for card_data in drawn_cards:
		var card_instance = card_ui_scene.instantiate() as CardUI
		if not card_instance:
			continue
			
		cards_container.add_child(card_instance)
		card_instance.setup(card_data)
		active_cards_ui.append(card_instance)

func update_selection(immediate: bool = false) -> void:
	for i in range(active_cards_ui.size()):
		active_cards_ui[i].set_selected(i == selected_index, immediate)

func confirm_selection() -> void:
	if not active or active_cards_ui.size() == 0 or selected_index >= active_cards_ui.size():
		return

	var selected_card_ui = active_cards_ui[selected_index]
	if not selected_card_ui or not selected_card_ui.card_data:
		return

	var points = progression_manager.get_upgrade_points() if progression_manager else 0
	if points <= 0:
		active = false
		await shake_card(selected_card_ui)
		active = true
		return

	active = false
	
	if progression_manager.spend_upgrade_point():
		selected_card_ui.card_data.apply_to_player(player)
		update_player_stats_display()

	await animate_card_selection(selected_card_ui)
	clear_cards()

	if deck_manager:
		deck_manager.roll_new_offer(3, player)

	if progression_manager and progression_manager.get_upgrade_points() > 0:
		selected_index = 0
		var viewport_size = get_viewport_rect().size
		cards_container.position.y = viewport_size.y + 50.0

		generate_cards()
		await get_tree().process_frame
		calculate_positions()

		await animate_open_cards_only()
		active = true
		update_selection(false)
	else:
		game_manager.close_shop()

func shake_card(card: CardUI) -> void:
	var original_pos_x = card.position.x
	var shake_tween = create_tween()
	shake_tween.tween_property(card, "position:x", original_pos_x - 4.0, 0.04)
	shake_tween.tween_property(card, "position:x", original_pos_x + 4.0, 0.04)
	shake_tween.tween_property(card, "position:x", original_pos_x - 2.0, 0.04)
	shake_tween.tween_property(card, "position:x", original_pos_x + 2.0, 0.04)
	shake_tween.tween_property(card, "position:x", original_pos_x, 0.04)
	await shake_tween.finished

func animate_card_selection(chosen_card: CardUI) -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	for card in active_cards_ui:
		if card == chosen_card:
			# Wybrana karta leci w górę z powiększeniem i zanika
			tween.tween_property(card, "position:y", -160.0, 0.25)
			tween.tween_property(card, "scale", Vector2(1.25, 1.25), 0.25)
			tween.tween_property(card, "modulate:a", 0.0, 0.25)
		else:
			# Pozostałe karty spadają w dół i zanikają
			tween.tween_property(card, "position:y", 160.0, 0.2)
			tween.tween_property(card, "scale", Vector2(0.8, 0.8), 0.2)
			tween.tween_property(card, "modulate:a", 0.0, 0.2)

	await tween.finished

func update_player_stats_display() -> void:
	if not player or not game_manager or not game_manager.ui_manager:
		return

	var stats = player.stats_component
	var atk_ctrl = player.get_attack_controller()
	var base_dmg = atk_ctrl.equipped_weapon.base_damage if atk_ctrl and atk_ctrl.equipped_weapon else 1.0
	var base_atk_spd = atk_ctrl.equipped_weapon.base_attack_speed if atk_ctrl and atk_ctrl.equipped_weapon else 3.0

	var player_damage: int = int(stats.get_final_damage(base_dmg)) if stats else int(base_dmg)
	var player_speed: int = int(player.get_movement_speed())
	var player_attack_speed: float = snappedf(stats.get_final_attack_speed(base_atk_spd), 0.1) if stats else base_atk_spd

	game_manager.ui_manager.update_stats_label(player_damage, player_speed, player_attack_speed)

	if player.health_component:
		var current_hp = int(player.health_component.get_health())
		game_manager.ui_manager.update_health_bar(current_hp)
func clear_cards() -> void:
	for card in active_cards_ui:
		if is_instance_valid(card):
			card.queue_free()
	active_cards_ui.clear()
	if cards_container:
		for child in cards_container.get_children():
			child.queue_free()

func animate_open() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if background_overlay:
		tween.tween_property(background_overlay, "modulate:a", 1.0, transition_duration)
	if cards_container:
		tween.tween_property(cards_container, "position:y", target_center_y, transition_duration)

	await tween.finished

func animate_open_cards_only() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cards_container, "position:y", target_center_y, transition_duration)
	await tween.finished

func animate_close() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	var offscreen_y = get_viewport_rect().size.y + 50.0

	if background_overlay:
		tween.tween_property(background_overlay, "modulate:a", 0.0, transition_duration * 0.75)
	if cards_container:
		tween.tween_property(cards_container, "position:y", offscreen_y, transition_duration * 0.75)

	await tween.finished

func fade_out_overlay() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	if background_overlay:
		tween.tween_property(background_overlay, "modulate:a", 0.0, transition_duration * 0.7)
		await tween.finished
