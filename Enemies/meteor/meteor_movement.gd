class_name MeteorMovement extends EnemyMovement

static func spawn_enemy(dmg: float, speed: float, health: float) -> EnemyMovement:
	my_scene = load("res://Enemies/meteor/meteor.tscn")
	return super(dmg, speed, health)
