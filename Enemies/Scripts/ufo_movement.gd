class_name UfoMovement extends EnemyMovement

var vertical_dir: Vector2 = Vector2(0, 1)

static func spawn_enemy(dmg: float, speed: float, health: float) -> EnemyMovement:
	my_scene = load("res://Enemies/ufo.tscn")
	var new_enemy: EnemyMovement = my_scene.instantiate()
	new_enemy.set_attack(dmg)
	new_enemy.set_move_speed(speed)
	new_enemy.set_health(health)
	return new_enemy

func do_movement() -> void:
	if position.y > 120:
		vertical_dir = -vertical_dir
	elif position.y < 10:
		vertical_dir = -vertical_dir
	velocity = (direction + vertical_dir) * move_speed
	move_and_slide()
