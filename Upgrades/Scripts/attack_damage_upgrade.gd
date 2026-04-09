class_name AttackDamageUpgrade extends PlayerUpgrade

func affect_player() -> void:
	player_attack_controler.add_damage(level)
	# print("I wanna increase player's attack damage")
