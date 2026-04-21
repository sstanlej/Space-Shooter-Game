extends Area2D

@onready var health_component : Node2D = $"../HealthComponent"

func damage(attack : float):
	if health_component:
		health_component.take_damage(attack)
