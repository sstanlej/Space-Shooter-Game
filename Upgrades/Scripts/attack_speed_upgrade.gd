class_name AttackSpeedUpgrade extends PlayerUpgrade

func affect_player() -> void:
	player_attack_controler.add_attack_speed(level)
	# print("I wanna increase player's attack speed")
