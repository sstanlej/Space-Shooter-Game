class_name MovementSpeedUpgrade extends PlayerUpgrade

func _ready() -> void:
	description = "Increases your movement speed by " + str(level) + "."


func affect_player() -> void:
	player.add_movement_speed(level)
	# print("I wanna increase player's movement speed")
