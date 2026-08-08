class_name MeteorEnemy extends Enemy

func do_movement(_delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()
	$Sprite2D.rotate(0.01)
