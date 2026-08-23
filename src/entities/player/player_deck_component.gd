class_name PlayerDeckComponent extends Node

signal deck_updated
signal stats_changed

# Wewnętrzna struktura reprezentująca fizyczną kartę w ręce gracza w trakcie rozgrywki
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
## Karty i ich poziomy, z którymi gracz zaczyna (np. Blaster, Damage lvl 1, Speed lvl 1, AtkSpeed lvl 1)
@export var starting_cards: Array[StartingCardConfig] = []

@export_group("Stat Level Scaling Formulas (Balans Gry)")
# ==============================================================================
# TUTAJ MODYFIKUJESZ PRZELICZNIKI I WARTOŚCI BAZOWE STATYSTYK DLA POZIOMÓW (1..N)
# ==============================================================================
## Obrażenia: Lvl 1 = 1 DMG, Lvl 2 = 2 DMG itd.
@export var damage_per_level: float = 1.0

## Prędkość statku: Lvl 1 = 60 px/s, każdy kolejny poziom daje +20 px/s (Lvl 3 = 100, Lvl 5 = 140)
@export var base_speed: float = 40.0
@export var speed_per_level: float = 20.0

## Szybkostrzelność: Lvl 1 = 1.0 (baza), każdy poziom w górę to +15% szybszy strzał
@export var attack_speed_baseline_level: int = 1
@export var attack_speed_step_ratio: float = 0.15

@export var health_per_level: float = 1.0

@export_group("Ice Physics & Visual Tuning")
@export var base_acceleration: float = 950.0
@export var base_friction: float = 750.0
@export var base_tilt_degrees: float = 8.0
@export var max_tilt_cap_degrees: float = 20.0

# --- STAN TALII I GRACZA W RUNIE ---
var active_deck: Array[CardInstance] = []
var equipped_weapon: WeaponData = null

# Poziomy statystyk wyliczane dynamicznie z talii
var damage_level: int = 1
var speed_level: int = 1
var attack_speed_level: int = 1
var projectiles_level: int = 1
var max_health_level: int = 5
var agility_level: int = 1
var shield_charges: int = 0

func _ready() -> void:
	initialize_starting_deck()

func initialize_starting_deck() -> void:
	active_deck.clear()
	equipped_weapon = null

	for config in starting_cards:
		if config and config.card_data:
			_register_card_to_deck(config.card_data, config.starting_level)

	recalculate_all_stats()

# --- ZARZĄDZANIE KARTAMI (API DLA SKLEPU I EVENTÓW) ---

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
			# Karty INSTANT wykonują tylko efekt i NIE trafiają do talii
			pass

	recalculate_all_stats()

func _upgrade_or_add_stat_card(card: UpgradeCardData) -> void:
	var existing = get_card_instance(card)
	if existing:
		existing.level += 1
	else:
		active_deck.append(CardInstance.new(card, 1))

func _equip_weapon_card(card: UpgradeCardData) -> void:
	if not card.weapon_data:
		return

	# Usuwamy dotychczasową kartę broni z talii
	for i in range(active_deck.size() - 1, -1, -1):
		if active_deck[i].data.card_type == UpgradeCardData.CardType.WEAPON:
			active_deck.remove_at(i)

	# Dodajemy nową broń
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
	shield_charges = card.max_charges
	sync_shield_with_health_component()

func add_or_refresh_shield(amount: int) -> void:
	shield_charges = amount
	sync_shield_with_health_component()
	deck_updated.emit()

func consume_shield_charge() -> int:
	if shield_charges > 0:
		shield_charges -= 1

		# Aktualizacja instancji tarczy w talii
		for i in range(active_deck.size() - 1, -1, -1):
			if active_deck[i].data.card_type == UpgradeCardData.CardType.USABLE and "shield" in active_deck[i].data.title.to_lower():
				active_deck[i].charges = shield_charges
				if shield_charges <= 0:
					active_deck.remove_at(i) # Karta fizycznie znika z talii!
				break

		deck_updated.emit()
	return shield_charges

func sync_shield_with_health_component() -> void:
	var player = get_parent() as Player
	if player and player.health_component:
		player.health_component.shield_charges = shield_charges

func _register_card_to_deck(card: UpgradeCardData, start_lvl: int) -> void:
	if card.card_type == UpgradeCardData.CardType.WEAPON:
		_equip_weapon_card(card)
	elif card.card_type == UpgradeCardData.CardType.USABLE:
		_add_or_refresh_usable_card(card)
	elif card.card_type == UpgradeCardData.CardType.STAT:
		active_deck.append(CardInstance.new(card, start_lvl))

func upgrade_stat_by_type(stat: UpgradeCardData.StatType, levels: int = 1) -> void:
	match stat:
		UpgradeCardData.StatType.DAMAGE: damage_level += levels
		UpgradeCardData.StatType.SPEED: speed_level += levels
		UpgradeCardData.StatType.ATTACK_SPEED: attack_speed_level += levels
		UpgradeCardData.StatType.PROJECTILES: projectiles_level += levels
		UpgradeCardData.StatType.MAX_HEALTH: max_health_level += levels
		UpgradeCardData.StatType.AGILITY: agility_level += levels
	recalculate_all_stats()

# --- PRZELICZANIE STATYSTYK ---

func recalculate_all_stats() -> void:
	# Reset do poziomów bazowych
	damage_level = 1
	speed_level = 1
	attack_speed_level = 1
	projectiles_level = 1
	max_health_level = 8
	agility_level = 1

	for instance in active_deck:
		if instance.data.card_type == UpgradeCardData.CardType.STAT:
			match instance.data.stat_type:
				UpgradeCardData.StatType.DAMAGE: damage_level = instance.level
				UpgradeCardData.StatType.SPEED: speed_level = instance.level
				UpgradeCardData.StatType.ATTACK_SPEED: attack_speed_level = instance.level
				UpgradeCardData.StatType.PROJECTILES: projectiles_level = instance.level
				UpgradeCardData.StatType.MAX_HEALTH: max_health_level = instance.level
				UpgradeCardData.StatType.AGILITY: agility_level = instance.level

	var player = get_parent() as Player
	if player and player.health_component:
		player.health_component.set_max_health(int(get_final_max_health()))

	stats_changed.emit()
	deck_updated.emit()

# --- GETTERY STATYSTYK I FIZYKI DLA KOMPONENTÓW ---

func get_final_movement_speed() -> float:
	return max(1.0, base_speed + (speed_level - 1) * speed_per_level)

func get_final_damage(base_weapon_damage: float = 1.0) -> float:
	return float(damage_level) * base_weapon_damage * damage_per_level

func get_final_attack_speed(base_weapon_attack_speed: float = 1.0) -> float:
	var multiplier = 1.0 + (attack_speed_level - attack_speed_baseline_level) * attack_speed_step_ratio
	return max(0.1, base_weapon_attack_speed * max(0.1, multiplier))

func get_final_projectiles_count(base_count: int = 1) -> int:
	return max(1, base_count + (projectiles_level - 1))

func get_final_max_health() -> float:
	return max(1.0, max_health_level * health_per_level)

func get_dynamic_acceleration() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return base_acceleration * pow(speed_ratio, 1.25) * (1.0 + (agility_level - 1) * 0.1)

func get_dynamic_friction() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return base_friction * pow(speed_ratio, 1.25) * (1.0 + (agility_level - 1) * 0.1)

func get_dynamic_max_tilt() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return clampf(base_tilt_degrees * speed_ratio, 4.0, max_tilt_cap_degrees)

# --- METODY POMOCNICZE TALII ---

func get_card_instance(card_data: UpgradeCardData) -> CardInstance:
	for inst in active_deck:
		if inst.data == card_data:
			return inst
		if not inst.data.card_id.is_empty() and inst.data.card_id == card_data.card_id:
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