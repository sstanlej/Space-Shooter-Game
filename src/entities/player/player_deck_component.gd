class_name PlayerDeckComponent extends Node

signal deck_updated

class CardInstance:
	var data: UpgradeCardData
	var level: int = 1
	var charges: int = 0
	var is_equipped: bool = false

	func _init(p_data: UpgradeCardData, p_level: int = 1, p_charges: int = 0) -> void:
		data = p_data
		level = p_level
		charges = p_charges

@export_group("Starting Deck Configuration")
@export var starting_cards: Array[StartingCardConfig] = []

var active_deck: Array[CardInstance] = []
var equipped_weapon: WeaponData = null

func _ready() -> void:
	initialize_starting_deck()

func initialize_starting_deck() -> void:
	active_deck.clear()
	equipped_weapon = null

	for config in starting_cards:
		if config and config.card_data:
			_register_card_to_deck(config.card_data, config.starting_level)

	_sync_stats()

func apply_card(card: UpgradeCardData) -> void:
	if not card:
		return

	match card.card_type:
		UpgradeCardData.CardType.STAT:
			_upgrade_or_add_stat_card(card)
		UpgradeCardData.CardType.WEAPON:
			_equip_weapon_card(card)
		UpgradeCardData.CardType.USABLE:
			_add_or_refresh_usable_card(card)
		UpgradeCardData.CardType.INSTANT:
			pass

	_sync_stats()

func _upgrade_or_add_stat_card(card: UpgradeCardData) -> void:
	var existing = get_card_instance(card)
	if existing:
		existing.level += 1
	else:
		active_deck.append(CardInstance.new(card, 1))

func _equip_weapon_card(card: UpgradeCardData) -> void:
	if not card.weapon_data:
		return

	for i in range(active_deck.size() - 1, -1, -1):
		if active_deck[i].data.card_type == UpgradeCardData.CardType.WEAPON:
			active_deck.remove_at(i)

	var instance = CardInstance.new(card, 1)
	instance.is_equipped = true
	active_deck.insert(0, instance)
	equipped_weapon = card.weapon_data

	var player = get_parent() as Player
	if player and player.attack_controller:
		player.attack_controller.equip_weapon(equipped_weapon)

func _add_or_refresh_usable_card(card: UpgradeCardData) -> void:
	var existing = get_card_instance(card)
	if existing:
		existing.charges = card.max_charges
	else:
		active_deck.append(CardInstance.new(card, 1, card.max_charges))

	var player = get_parent() as Player
	if card.usable_type == UpgradeCardData.UsableType.SHIELD and player and player.health_component:
		player.health_component.set_shield_charges(card.max_charges)

func _register_card_to_deck(card: UpgradeCardData, start_lvl: int) -> void:
	if card.card_type == UpgradeCardData.CardType.WEAPON:
		_equip_weapon_card(card)
	elif card.card_type == UpgradeCardData.CardType.USABLE:
		_add_or_refresh_usable_card(card)
	elif card.card_type == UpgradeCardData.CardType.STAT:
		active_deck.append(CardInstance.new(card, start_lvl))

func sync_shield_from_health(remaining_charges: int) -> void:
	for i in range(active_deck.size() - 1, -1, -1):
		var card_data = active_deck[i].data
		if card_data.card_type == UpgradeCardData.CardType.USABLE and card_data.usable_type == UpgradeCardData.UsableType.SHIELD:
			active_deck[i].charges = remaining_charges
			if remaining_charges <= 0:
				active_deck.remove_at(i)
			break
	deck_updated.emit()

func _sync_stats() -> void:
	var player = get_parent() as Player
	if player and player.stats_component:
		player.stats_component.update_from_deck(active_deck)
	deck_updated.emit()

func get_card_instance(card_data: UpgradeCardData) -> CardInstance:
	for inst in active_deck:
		if inst.data == card_data or (not inst.data.card_id.is_empty() and inst.data.card_id == card_data.card_id):
			return inst
		if inst.data.card_type == UpgradeCardData.CardType.STAT and card_data.card_type == UpgradeCardData.CardType.STAT:
			if inst.data.stat_type != UpgradeCardData.StatType.NONE and inst.data.stat_type == card_data.stat_type:
				return inst
	return null

func get_card_level(card_data: UpgradeCardData) -> int:
	var inst = get_card_instance(card_data)
	return inst.level if inst else 0

func get_active_deck() -> Array[CardInstance]:
	return active_deck

func get_final_damage(base_weapon_damage: float = 1.0) -> float:
	var player = get_parent() as Player
	if player and player.stats_component:
		return player.stats_component.get_final_damage(base_weapon_damage)
	return base_weapon_damage

func get_final_movement_speed() -> float:
	var player = get_parent() as Player
	if player and player.stats_component:
		return player.stats_component.get_movement_speed()
	return 200.0

func get_final_attack_speed(base_weapon_attack_speed: float = 1.0) -> float:
	var player = get_parent() as Player
	if player and player.stats_component:
		return player.stats_component.get_final_attack_speed(base_weapon_attack_speed)
	return base_weapon_attack_speed

func get_final_projectiles_count(base_count: int = 1) -> int:
	var player = get_parent() as Player
	if player and player.stats_component:
		return player.stats_component.get_final_projectiles_count(base_count)
	return base_count