class_name HealEffect extends CardEffect

@export var heal_amount: int = 25

func can_appear(player: Player) -> bool:
	if not player:
		return false

	var hc = player.get_health_component() if player.has_method("get_health_component") else player.get("health_component")
	if not hc:
		return false

	var current_hp: float = 0.0
	var max_hp: float = 0.0

	if hc.has_method("get_health"):
		current_hp = hc.get_health()
	elif "current_health" in hc:
		current_hp = hc.current_health
	elif "health" in hc:
		current_hp = hc.health

	if hc.has_method("get_max_health"):
		max_hp = hc.get_max_health()
	elif "max_health" in hc:
		max_hp = hc.max_health

	return int(round(current_hp)) < int(round(max_hp))

func execute(player: Player) -> void:
	var hc = player.get_health_component() if player.has_method("get_health_component") else player.get("health_component")
	if hc and hc.has_method("heal"):
		hc.heal(heal_amount)