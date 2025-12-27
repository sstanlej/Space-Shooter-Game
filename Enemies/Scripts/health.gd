class_name Health extends Node2D
@export var MAX_HEALTH : float = 4
var health : float = MAX_HEALTH

func set_health(new_health: float):
	health = new_health
	
func get_health() -> float:
	return health

func take_damage(attack : float) -> void:
	health -= attack
	
	if health <= 0:
		die()

func die() -> void:
	get_parent().queue_free()
