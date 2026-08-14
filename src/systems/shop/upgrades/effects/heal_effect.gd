class_name HealEffect extends CardEffect

@export var heal_amount: int = 25

func execute(player: Player) -> void:
	var hc = player.get_health_component() if player.has_method("get_health_component") else player.health_component
	if hc and hc.has_method("heal"):
		hc.heal(heal_amount)