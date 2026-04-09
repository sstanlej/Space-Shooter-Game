class_name AttackDamageUpgrade extends PlayerUpgrade

func _ready() -> void:
	description = "Attack damage upgrade. Increases your attack damage by " + str(level) + "."

func affect_player() -> void:
	player_attack_controler.add_damage(level)
	# print("I wanna increase player's attack damage")
