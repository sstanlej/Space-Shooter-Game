class_name UfoMovement extends EnemyMovement

var vertical_dir: Vector2 = Vector2(0, 1)
var amplitude: float = 30
var vertical_speed_mult: float = 1

static func spawn_enemy(dmg: float, speed: float, health: float) -> EnemyMovement:
	my_scene = load("res://Enemies/ufo.tscn")
	return super(dmg, speed, health)

func do_movement() -> void:
	if position.y > Spawner.max_y:
		vertical_dir = -vertical_dir
	elif position.y < Spawner.min_y:
		vertical_dir = -vertical_dir
	velocity = (direction + vertical_dir * vertical_speed_mult) * move_speed
	move_and_slide()
