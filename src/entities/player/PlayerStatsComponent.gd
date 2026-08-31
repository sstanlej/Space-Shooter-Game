class_name PlayerStatsComponent extends Node

signal stats_changed

@export_group("Base Fallback Stats")
@export var base_speed: float = 40.0

var bonus_damage: float = 0.0
var bonus_speed: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_projectiles: int = 0
var bonus_health: int = 0
var bonus_agility: float = 0.0

func _reset_bonus_values() -> void:
	bonus_damage = 0.0
	bonus_speed = 0.0
	bonus_attack_speed = 0.0
	bonus_projectiles = 0
	bonus_health = 0
	bonus_agility = 0.0

func reset_stats() -> void:
	_reset_bonus_values()
	stats_changed.emit()

func update_from_deck(active_deck: Array) -> void:
	_reset_bonus_values()

	for instance in active_deck:
		var card: UpgradeCardData = instance.data
		if not card or card.card_type != UpgradeCardData.CardType.STAT:
			continue

		var bonus = card.get_stat_bonus(instance.level)

		match card.stat_type:
			UpgradeCardData.StatType.DAMAGE:
				bonus_damage += bonus
			UpgradeCardData.StatType.SPEED:
				bonus_speed += bonus
			UpgradeCardData.StatType.ATTACK_SPEED:
				bonus_attack_speed += bonus
			UpgradeCardData.StatType.PROJECTILES:
				bonus_projectiles += int(bonus)
			UpgradeCardData.StatType.MAX_HEALTH:
				bonus_health += int(bonus)
			UpgradeCardData.StatType.AGILITY:
				bonus_agility += bonus

	var player = get_parent() as Player
	if player and player.health_component:
		var target_max = player.health_component.base_max_health + bonus_health
		player.health_component.set_max_health(target_max)

	stats_changed.emit()

# --- FINAL STAT GETTERS ---

func get_movement_speed() -> float:
	return maxf(1.0, base_speed + bonus_speed)

func get_final_damage(base_weapon_damage: float = 1.0) -> float:
	return maxf(0.1, base_weapon_damage + bonus_damage)

func get_final_attack_speed(base_weapon_attack_speed: float = 1.0) -> float:
	return maxf(0.1, base_weapon_attack_speed * (1.0 + bonus_attack_speed))

func get_final_projectiles_count(base_count: int = 1) -> int:
	return max(1, base_count + bonus_projectiles)

func get_agility_multiplier() -> float:
	return 1.0 + bonus_agility