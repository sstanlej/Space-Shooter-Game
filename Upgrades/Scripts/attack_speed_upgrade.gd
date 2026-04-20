class_name AttackSpeedUpgrade extends PlayerUpgrade

func _ready() -> void:
	description = "Increases your attack speed by " + str(level) + "."


func apply_upgrade() -> void:
	player_attack_controler.add_attack_speed(level)
	# print("I wanna increase player's attack speed")
