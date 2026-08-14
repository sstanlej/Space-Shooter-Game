class_name StatModifierEffect extends CardEffect

enum StatType { DAMAGE, ATTACK_SPEED, MOVEMENT_SPEED }

@export var stat_type: StatType
@export var flat_value: float = 0.0
@export var percent_value: float = 0.0

func execute(player: Player) -> void:
	var stats = player.stats_component
	if not stats:
		return

	match stat_type:
		StatType.DAMAGE:
			if flat_value != 0.0: stats.add_flat_damage(flat_value)
			if percent_value != 0.0: stats.add_damage_multiplier(percent_value)
		StatType.ATTACK_SPEED:
			if percent_value != 0.0: stats.add_attack_speed_multiplier(percent_value)
		StatType.MOVEMENT_SPEED:
			if flat_value != 0.0: stats.add_movement_speed(flat_value)