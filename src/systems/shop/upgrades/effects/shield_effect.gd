class_name ShieldEffect extends CardEffect

@export var shield_charges: int = 3

func execute(player: Player) -> void:
	var deck = player.get_deck_component() if player else null
	if deck:
		deck.add_or_refresh_shield(shield_charges)