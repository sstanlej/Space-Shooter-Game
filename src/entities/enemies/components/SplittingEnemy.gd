class_name SplittingEnemy extends Enemy

@export var spawn_y_step: int = 20

func _on_health_component_died() -> void:
	spawn_death_effect()
	enemy_died.emit(data.enemy_score_reward, data.enemy_xp_reward)
	if data and data.split_enemy_data and data.split_enemy_count > 0:
		call_deferred("spawn_split_enemies", data.split_enemy_data, data.split_enemy_count)
	queue_free()

func spawn_split_enemies(enemy_data: EnemyData, count: int) -> void:
	var spawner = get_tree().get_first_node_in_group("spawner")

	var total_height = (count - 1) * spawn_y_step
	var start_y = global_position.y - (total_height / 2.0)

	for i in range(count):
		var spawn_pos = Vector2(global_position.x, start_y + (i * spawn_y_step))

		if spawner:
			spawner.spawn_enemy(spawn_pos, enemy_data)
		else:
			push_error("Spawner not found in group 'spawner'!")
