class_name AttackDamageUpgrade extends PlayerUpgrade

func _ready() -> void:
	description = "Increases your attack damage by " + str(level) + "."

func apply_upgrade() -> void:
	player_attack_controler.add_damage(level)
	# print("I wanna increase player's attack damage")
