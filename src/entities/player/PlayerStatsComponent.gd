class_name PlayerStatsComponent extends Node

signal stats_changed

@export_group("Stat Level Scaling Formulas")
@export var damage_per_level: float = 1.0

@export var base_speed: float = 40.0
@export var speed_per_level: float = 10.0

@export var attack_speed_baseline_level: int = 1
@export var attack_speed_step_ratio: float = 0.15

@export var health_per_level: int = 1

# --- RUN STATE ---
var damage_level: int = 1
var speed_level: int = 1
var attack_speed_level: int = 1
var projectiles_level: int = 0
var bonus_health_level: int = 0
var agility_level: int = 1

func reset_stats() -> void:
	damage_level = 1
	speed_level = 1
	attack_speed_level = 1
	projectiles_level = 0
	bonus_health_level = 0
	agility_level = 1
	stats_changed.emit()

func update_from_deck(active_deck: Array) -> void:
	# Reset levels to baseline
	damage_level = 1
	speed_level = 1
	attack_speed_level = 1
	projectiles_level = 0
	bonus_health_level = 0
	agility_level = 1

	for instance in active_deck:
		if instance.data.card_type == UpgradeCardData.CardType.STAT:
			match instance.data.stat_type:
				UpgradeCardData.StatType.DAMAGE:
					damage_level = instance.level
				UpgradeCardData.StatType.SPEED:
					speed_level = instance.level
				UpgradeCardData.StatType.ATTACK_SPEED:
					attack_speed_level = instance.level
				UpgradeCardData.StatType.PROJECTILES:
					projectiles_level = instance.level
				UpgradeCardData.StatType.MAX_HEALTH:
					bonus_health_level = instance.level
				UpgradeCardData.StatType.AGILITY:
					agility_level = instance.level

	var player = get_parent() as Player
	if player and player.health_component:
		var target_max = player.health_component.base_max_health + (bonus_health_level * health_per_level)
		player.health_component.set_max_health(target_max)

	stats_changed.emit()

# --- STAT GETTERS ---

func get_movement_speed() -> float:
	return max(1.0, base_speed + (speed_level - 1) * speed_per_level)

func get_final_damage(base_weapon_damage: float = 1.0) -> float:
	return float(damage_level) * base_weapon_damage * damage_per_level

func get_final_attack_speed(base_weapon_attack_speed: float = 1.0) -> float:
	var multiplier = 1.0 + (attack_speed_level - attack_speed_baseline_level) * attack_speed_step_ratio
	return max(0.1, base_weapon_attack_speed * max(0.1, multiplier))

func get_final_projectiles_count(base_count: int = 1) -> int:
	return max(1, base_count + projectiles_level)

func get_agility_multiplier() -> float:
	return 1.0 + (agility_level - 1) * 0.1