class_name StatModifierEffect extends CardEffect

@export var stat_type: UpgradeCardData.StatType = UpgradeCardData.StatType.DAMAGE
@export var levels_to_add: int = 1

func execute(player: Player) -> void:
	var deck = player.get_deck_component() if player else null
	if deck:
		deck.upgrade_stat_by_type(stat_type, levels_to_add)
