class_name DummySpawnPoint extends EnemyMovement

static func spawn_enemy(dmg: float, speed: float, health: float) -> EnemyMovement:
	my_scene = load("res://Enemies/dummy_spawn_point.tscn")
	var new_enemy: EnemyMovement = my_scene.instantiate()
	return new_enemy

func _physics_process(_delta: float) -> void:
	pass

