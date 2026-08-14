class_name HealEffect extends CardEffect

@export var heal_amount: int = 25

func can_appear(player: Player) -> bool:
	if not player:
		return true
	
	var hc = player.get_health_component() if player.has_method("get_health_component") else player.health_component
	if hc:
		var current_hp = hc.get_health() if hc.has_method("get_health") else hc.current_health
		var max_hp = hc.get_max_health() if hc.has_method("get_max_health") else hc.max_health
		return current_hp < max_hp

	return true

func execute(player: Player) -> void:
	var hc = player.get_health_component() if player.has_method("get_health_component") else player.health_component
	if hc and hc.has_method("heal"):
		hc.heal(heal_amount)