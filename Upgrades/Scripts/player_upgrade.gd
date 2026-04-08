class_name PlayerUpgrade extends Sprite2D

@onready var player: Player = $"../../../Player"
@onready var player_attack_controler: AttackControler = $"../../../Player/AttackControler"
@export var level: float = 1
@export var description: String = "I am an upgrade"

func affect_player() -> void:
	pass
