class_name HealthComponent extends Node

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal healed(amount: int)
signal died

@export_group("Health Settings")
@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func set_max_health(new_max: int) -> void:
	max_health = max(1, new_max)
	current_health = clampi(current_health, 1, max_health)
	health_changed.emit(current_health, max_health)

func set_health(new_health: int) -> void:
	max_health = max(1, new_health)
	current_health = clampi(new_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func heal(amount: int) -> void:
	if current_health >= max_health or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return

	current_health -= amount
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		died.emit()

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return current_health