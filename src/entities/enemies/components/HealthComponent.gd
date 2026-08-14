class_name HealthComponent extends Node

signal health_changed(current_health: float, max_health: float)
signal damage_taken
signal died
signal healed(amount: float)

@export var max_health: int = 10
var current_health: int

func _ready() -> void:
	current_health = max_health

func set_health(new_health: int) -> void:
	max_health = new_health
	current_health = new_health
	health_changed.emit(current_health, max_health)

# Dodaj funkcję heal:
func heal(amount: float) -> void:
	if current_health >= max_health or amount <= 0:
		return
	
	current_health = min(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)
	print("[HealthComponent] Healed by ", amount, ". Current HP: ", current_health, "/", max_health)

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
