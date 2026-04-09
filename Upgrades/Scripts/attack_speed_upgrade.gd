class_name AttackSpeedUpgrade extends PlayerUpgrade

func _ready() -> void:
	description = "Attack speed upgrade. Increases your attack speed by " + str(level) + "."


func affect_player() -> void:
	player_attack_controler.add_attack_speed(level)
	# print("I wanna increase player's attack speed")
