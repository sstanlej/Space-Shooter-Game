class_name PlayerStatsComponent extends Node

signal stats_changed

enum StatType {
	DAMAGE,
	SPEED,
	ATTACK_SPEED,
	PROJECTILES,
	MAX_HEALTH,
	AGILITY
}

@export_group("Starting Stat Levels (Natural Numbers)")
@export var damage_level: int = 1
@export var speed_level: int = 3
@export var attack_speed_level: int = 3
@export var projectiles_level: int = 1
@export var max_health_level: int = 5
@export var agility_level: int = 1

@export_group("Scaling Formulas & Baselines")
## Prędkość na każdy poziom (Poziom 5 = 200.0 px/s)
@export var speed_per_level: float = 20

## Attack speed: Poziom 3 = 1.0 (baza), każdy poziom to +/- 15%
@export var attack_speed_baseline_level: int = 3
@export var attack_speed_step_ratio: float = 0.15
## Zdrowie na każdy poziom (Poziom 5 = 100 HP)
@export var health_per_level: float = 20.0

@export_group("Ice Physics & Visual Tuning")
@export var base_acceleration: float = 950.0
@export var base_friction: float = 750.0
@export var base_tilt_degrees: float = 8.0
@export var max_tilt_cap_degrees: float = 20.0

# --- FORMULARZE WYLICZANIA STATYSTYK DLA GRY ---

func get_final_movement_speed() -> float:
	return max(1.0, speed_level * speed_per_level)

func get_final_damage(base_weapon_damage: float = 1.0) -> float:
	return float(damage_level) * base_weapon_damage

func get_final_attack_speed(base_weapon_attack_speed: float) -> float:
	var multiplier = 1.0 + (attack_speed_level - attack_speed_baseline_level) * attack_speed_step_ratio
	return max(0.1, base_weapon_attack_speed * max(0.1, multiplier))

func get_final_projectiles_count(base_count: int) -> int:
	# Poziom 1 = bazowa liczba pocisków broni, każdy kolejny dodaje +1
	return max(1, base_count + (projectiles_level - 1))

func get_final_max_health() -> float:
	return max(1.0, max_health_level * health_per_level)

# --- FIZYKA RUCHU ZALEŻNA OD STATYSTYK ---

func get_dynamic_acceleration() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return base_acceleration * pow(speed_ratio, 1.25) * (1.0 + (agility_level - 1) * 0.1)

func get_dynamic_friction() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return base_friction * pow(speed_ratio, 1.25) * (1.0 + (agility_level - 1) * 0.1)

func get_dynamic_max_tilt() -> float:
	var speed_ratio = get_final_movement_speed() / 200.0
	return clampf(base_tilt_degrees * speed_ratio, 4.0, max_tilt_cap_degrees)

# --- API DLA KART ULEPSZEŃ I KLAS ---

func upgrade_stat(stat: StatType, levels: int = 1) -> void:
	match stat:
		StatType.DAMAGE:
			damage_level += levels
		StatType.SPEED:
			speed_level += levels
		StatType.ATTACK_SPEED:
			attack_speed_level += levels
		StatType.PROJECTILES:
			projectiles_level += levels
		StatType.MAX_HEALTH:
			max_health_level += levels
		StatType.AGILITY:
			agility_level += levels
	stats_changed.emit()

func get_stat_level(stat: StatType) -> int:
	match stat:
		StatType.DAMAGE: return damage_level
		StatType.SPEED: return speed_level
		StatType.ATTACK_SPEED: return attack_speed_level
		StatType.PROJECTILES: return projectiles_level
		StatType.MAX_HEALTH: return max_health_level
		StatType.AGILITY: return agility_level
	return 1

func reset_to_defaults(dmg: int = 3, spd: int = 5, atk_spd: int = 3, proj: int = 1, hp: int = 5) -> void:
	damage_level = dmg
	speed_level = spd
	attack_speed_level = atk_spd
	projectiles_level = proj
	max_health_level = hp
	agility_level = 1
	stats_changed.emit()

# --- KOMPATYBILNOŚĆ WSTECZNA (LEGACY BRIDGES) ---

func add_attack_speed_multiplier(_amount: float = 0.0) -> void:
	upgrade_stat(StatType.ATTACK_SPEED, 1)

func add_flat_damage(_amount: float = 0.0) -> void:
	upgrade_stat(StatType.DAMAGE, 1)

func add_damage_multiplier(_amount: float = 0.0) -> void:
	upgrade_stat(StatType.DAMAGE, 1)

func add_movement_speed(_amount: float = 0.0) -> void:
	upgrade_stat(StatType.SPEED, 1)

func add_extra_projectiles(amount: int = 1) -> void:
	upgrade_stat(StatType.PROJECTILES, amount)

func reset_stats() -> void:
	reset_to_defaults()