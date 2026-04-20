class_name PlayerUpgrade extends Sprite2D

@export var player: Player
@export var player_attack_controler: AttackControler
@export var level: float = 1
@export var description: String = "I am an upgrade"

func affect_player(target_player: Player) -> void:
	player = target_player
	player_attack_controler = player.get_attack_controler()
	apply_upgrade()

func apply_upgrade() -> void:
	pass
