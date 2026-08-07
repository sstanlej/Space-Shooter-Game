class_name HealthComponent extends Node

signal health_changed(current_health: float, max_health: float)
signal damage_taken
signal died

@export var max_health: int = 10
var current_health: int

func _ready() -> void:
	current_health = max_health

func set_health(new_health: int) -> void:
	max_health = new_health
	current_health = new_health
	health_changed.emit(current_health, max_health)

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return current_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	damage_taken.emit()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		died.emit()
