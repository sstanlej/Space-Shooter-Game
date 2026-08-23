class_name HealEffect extends CardEffect

@export var heal_amount: int = 25

func can_appear(player: Player) -> bool:
	if not player or not player.health_component:
		return false
	var hc = player.health_component
	return hc.get_health() < hc.get_max_health()

func execute(player: Player) -> void:
	if player and player.health_component:
		player.health_component.heal(heal_amount)