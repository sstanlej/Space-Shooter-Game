class_name AttackControlerBooster extends Collectable

@export var duration_time: float = 2
@export var level: float = 3
var attack_controler: AttackControler

func _ready() -> void:
	$DurationTime.wait_time = duration_time

func get_duration() -> float:
	return duration_time
	
func set_duration(new_duration: float):
	duration_time = new_duration
	$DurationTime.wait_time = duration_time

func get_attack_controler() -> AttackControler:
	if !player:
		return
	for child in player.get_children():
		if child is AttackControler:
			attack_controler = child
			return attack_controler
	return null

func revert_changes() -> void:
	pass

func _on_duration_time_timeout() -> void:
	revert_changes()
