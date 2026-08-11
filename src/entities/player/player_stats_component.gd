class_name PlayerStatsComponent extends Node

signal stats_changed

@export var base_max_health: float = 100.0
@export var base_movement_speed: float = 200.0

var flat_damage_bonus: float = 0.0
var damage_multiplier: float = 1.0

var attack_speed_multiplier: float = 1.0
var extra_projectiles: int = 0

var movement_speed_bonus: float = 0.0
var movement_speed_multiplier: float = 1.0

func get_final_movement_speed() -> float:
	return (base_movement_speed + movement_speed_bonus) * movement_speed_multiplier

func get_final_damage(base_weapon_damage: float) -> float:
	return (base_weapon_damage + flat_damage_bonus) * damage_multiplier

func get_final_attack_speed(base_weapon_attack_speed: float) -> float:
	return base_weapon_attack_speed * attack_speed_multiplier

func get_final_projectiles_count(base_count: int) -> int:
	return base_count + extra_projectiles

func add_flat_damage(amount: float) -> void:
	flat_damage_bonus += amount
	stats_changed.emit()

func add_damage_multiplier(amount: float) -> void:
	damage_multiplier += amount
	stats_changed.emit()

func add_attack_speed_multiplier(amount: float) -> void:
	attack_speed_multiplier += amount
	stats_changed.emit()

func add_extra_projectiles(amount: int) -> void:
	extra_projectiles += amount
	stats_changed.emit()

func add_movement_speed(amount: float) -> void:
	movement_speed_bonus += amount
	stats_changed.emit()

func reset_stats() -> void:
	flat_damage_bonus = 0.0
	damage_multiplier = 1.0
	attack_speed_multiplier = 1.0
	extra_projectiles = 0
	movement_speed_bonus = 0.0
	movement_speed_multiplier = 1.0
	stats_changed.emit()