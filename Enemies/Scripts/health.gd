extends Node2D
@export var MAX_HEALTH : float = 4
var health : float

func _ready() -> void:
	health = MAX_HEALTH
	
func take_damage(attack : float) -> void:
	health -= attack
	
	if health <= 0:
		get_parent().queue_free()
