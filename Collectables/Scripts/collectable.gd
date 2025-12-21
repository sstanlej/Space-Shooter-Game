class_name Collectable extends Area2D

@export var duration_time: float = 2
@export var new_cooldown: float = 0.1
var old_cooldown: float
var attack_controler: AttackControler

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DurationTime.wait_time = duration_time

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		var player: Player = area.get_parent()
		for child in player.get_children():
			if child is AttackControler:
				attack_controler = child
				break
				
		old_cooldown = attack_controler.get_cooldown()
		print(old_cooldown)
		attack_controler.set_cooldown(new_cooldown)
		
		$DurationTime.start()
		hide()
		set_deferred("monitoring", false)


func _on_duration_time_timeout() -> void:
	print("timeout")
	attack_controler.set_cooldown(old_cooldown)
	queue_free()
