class_name UfoEnemy extends Enemy

var vertical_dir: Vector2 = Vector2.DOWN
@export var vertical_speed_multiplier: float = 1

func do_movement(_delta: float) -> void:
	if position.y > Spawner.max_y:
		vertical_dir = Vector2.UP
	elif position.y < Spawner.min_y:
		vertical_dir = Vector2.DOWN

	velocity = (direction + vertical_dir * vertical_speed_multiplier) * move_speed
	move_and_slide()