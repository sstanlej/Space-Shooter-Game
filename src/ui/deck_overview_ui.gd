class_name DeckOverviewUI extends Control

signal deck_overview_closed

@export_group("System References")
@export var game_manager: GameManager
@export var player: Player

@export_group("UI Elements")
@export var background_overlay: ColorRect
@export var cards_anchor: Control
@export var card_ui_scene: PackedScene
@export var your_deck_label: RichTextLabel

@export_group("Layout & Spacing Settings")
@export var card_spacing: float = 56.0
@export var selected_elevation_y: float = 32.0
@export var base_bottom_offset_y: float = 40.0
@export var transition_duration: float = 0.28

var active_cards_ui: Array[CardUI] = []
var selected_index: int = 0
var is_active: bool = false
var is_animating: bool = false
var main_tween: Tween

func _ready() -> void:
	if background_overlay:
		background_overlay.modulate.a = 0.0
	if your_deck_label:
		your_deck_label.modulate.a = 0.0
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or is_animating:
		return

	if event.is_action_pressed("right") and selected_index < active_cards_ui.size() - 1:
		selected_index += 1
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_select"):
			GlobalAudio.play_select()
		update_cards_layout()

	elif event.is_action_pressed("left") and selected_index > 0:
		selected_index -= 1
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_select"):
			GlobalAudio.play_select()
		update_cards_layout()

	elif event.is_action_pressed("deck_overview") or event.is_action_pressed("pause") or event.is_action_pressed("shop"):
		close_overview()

func show_overview() -> void:
	if is_animating:
		return

	if not player and game_manager and game_manager.player:
		player = game_manager.player

	show()
	selected_index = 0
	is_animating = true
	is_active = false

	generate_overview_cards()
	await animate_open()

	is_animating = false
	is_active = true

func close_overview() -> void:
	if is_animating:
		return

	is_animating = true
	is_active = false

	await animate_close()
	clear_cards()
	hide()

	is_animating = false
	deck_overview_closed.emit()

func generate_overview_cards() -> void:
	clear_cards()
	if not player or not card_ui_scene or not cards_anchor:
		return

	var deck = player.get_deck_component()
	if not deck:
		return

	for card_instance in deck.get_active_deck():
		var card_ui = card_ui_scene.instantiate() as CardUI
		if not card_ui:
			continue

		cards_anchor.add_child(card_ui)
		var label_text = format_card_overview_text(card_instance)
		card_ui.setup_as_overview_card(card_instance.data, label_text)
		active_cards_ui.append(card_ui)

func format_card_overview_text(instance: PlayerDeckComponent.CardInstance) -> String:
	var card = instance.data
	var deck = player.get_deck_component()

	match card.card_type:
		UpgradeCardData.CardType.WEAPON:
			return "[color=cyan]EQUIPPED WEAPON[/color]"

		UpgradeCardData.CardType.USABLE:
			return "[color=aquamarine]CHARGES: %d/%d[/color]" % [instance.charges, card.max_charges]

		UpgradeCardData.CardType.STAT:
			match card.stat_type:
				UpgradeCardData.StatType.DAMAGE:
					var current_dmg = deck.get_final_damage(deck.equipped_weapon.base_damage if deck.equipped_weapon else 1.0)
					return "[color=gold]LVL %d[/color]  (DMG: %d)" % [instance.level, int(current_dmg)]
				UpgradeCardData.StatType.SPEED:
					return "[color=gold]LVL %d[/color]  (%.0f px/s)" % [instance.level, deck.get_final_movement_speed()]
				UpgradeCardData.StatType.ATTACK_SPEED:
					var base_atk_spd = 1.0
					if deck and deck.equipped_weapon and "base_attack_speed" in deck.equipped_weapon:
						base_atk_spd = deck.equipped_weapon.base_attack_speed
					var shots_per_sec = deck.get_final_attack_speed(base_atk_spd) if deck else 1.0
					return "[color=gold]LVL %d[/color]  (%.1f shots/s)" % [instance.level, shots_per_sec]
				UpgradeCardData.StatType.MAX_HEALTH:
					var hc = player.health_component
					var hp_text = "HP: %d/%d" % [hc.get_health(), hc.get_max_health()] if hc else ""
					return "[color=gold]LVL %d[/color]  (%s)" % [instance.level, hp_text]
				UpgradeCardData.StatType.PROJECTILES:
					var base_count = deck.equipped_weapon.projectiles_per_shot if deck and deck.equipped_weapon else 1
					var total_count = deck.get_final_projectiles_count(base_count) if deck else 1
					return "[color=gold]LVL %d[/color]  (%d bullets)" % [instance.level, total_count]
				_:
					return "[color=gold]LVL %d[/color]" % instance.level

	return "[color=gold]LVL %d[/color]" % instance.level

# --- POZYCJONOWANIE KART ---

func calculate_card_target(index: int, total: int) -> Dictionary:
	var viewport_size = get_viewport_rect().size
	var center_x = viewport_size.x / 2.0
	var base_y = viewport_size.y - base_bottom_offset_y

	var mid_index = (total - 1) / 2.0
	var offset_from_mid = index - mid_index

	var card_w = active_cards_ui[index].size.x
	var card_h = active_cards_ui[index].size.y
	if card_w <= 0.0: card_w = active_cards_ui[index].custom_minimum_size.x
	if card_h <= 0.0: card_h = active_cards_ui[index].custom_minimum_size.y

	var target_x = center_x + (offset_from_mid * card_spacing) - (card_w / 2.0)
	var target_y = base_y - (card_h / 2.0)

	var is_selected = (index == selected_index)
	if is_selected:
		target_y -= selected_elevation_y

	return {
		"position": Vector2(target_x, target_y),
		"rotation": 0.0,
		"scale": Vector2(1.1, 1.1) if is_selected else Vector2(1.0, 1.0),
		"z_index": 20 if is_selected else index,
		# Pełna nieprzezroczystość (Alpha = 1.0) – nieaktywne karty są tylko przyciemnione:
		"modulate": Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.6, 0.6, 0.6, 1.0)
	}

func update_cards_layout(immediate: bool = false) -> void:
	var total = active_cards_ui.size()
	if total == 0:
		return

	for i in range(total):
		var card = active_cards_ui[i]
		var target = calculate_card_target(i, total)

		card.z_index = target.z_index
		card.modulate = target.modulate

		if immediate:
			card.position = target.position
			card.rotation_degrees = 0.0
			card.scale = target.scale
		else:
			card.animate_fan_transform(target.position, 0.0, target.scale, 0.18)

# --- ANIMACJE OTWIERANIA I ZAMYKANIA ---

func animate_open() -> void:
	if main_tween and main_tween.is_running():
		main_tween.kill()

	var viewport_size = get_viewport_rect().size
	var offscreen_y = viewport_size.y + 60.0
	var total = active_cards_ui.size()

	for i in range(total):
		var card = active_cards_ui[i]
		var target = calculate_card_target(i, total)
		card.position = Vector2(target.position.x, offscreen_y)
		card.rotation_degrees = 0.0
		card.scale = target.scale
		card.z_index = target.z_index
		card.modulate = target.modulate

	main_tween = create_tween().set_parallel(true)
	main_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if background_overlay:
		main_tween.tween_property(background_overlay, "modulate:a", 0.75, transition_duration)
	if your_deck_label:
		main_tween.tween_property(your_deck_label, "modulate:a", 1.0, transition_duration)

	for i in range(total):
		var card = active_cards_ui[i]
		var target = calculate_card_target(i, total)
		main_tween.tween_property(card, "position", target.position, transition_duration)

	await main_tween.finished

func animate_close() -> void:
	if main_tween and main_tween.is_running():
		main_tween.kill()

	var viewport_size = get_viewport_rect().size
	var offscreen_y = viewport_size.y + 60.0
	var total = active_cards_ui.size()
	var close_duration = transition_duration * 0.75

	main_tween = create_tween().set_parallel(true)
	main_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if background_overlay:
		main_tween.tween_property(background_overlay, "modulate:a", 0.0, close_duration)

	if your_deck_label:
		main_tween.tween_property(your_deck_label, "modulate:a", 0.0, close_duration)

	for i in range(total):
		var card = active_cards_ui[i]
		main_tween.tween_property(card, "position:y", offscreen_y, close_duration)
		main_tween.tween_property(card, "scale", Vector2(0.9, 0.9), close_duration)
		main_tween.tween_property(card, "modulate:a", 0.0, close_duration)

	await main_tween.finished

func clear_cards() -> void:
	for card in active_cards_ui:
		if is_instance_valid(card):
			card.queue_free()
	active_cards_ui.clear()
	if cards_anchor:
		for child in cards_anchor.get_children():
			child.queue_free()
