extends Area2D

@export var health_component : HealthComponent

func damage(attack : int):
	if health_component:
		health_component.take_damage(attack)
