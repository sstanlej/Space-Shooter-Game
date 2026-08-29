class_name SplitOnDeathComponent extends Node

@export var split_enemy_data: EnemyData
@export var split_count: int = 2
@export var min_radius: float = 12.0
@export var max_radius: float = 26.0
@export var suppress_death_effect: bool = false

var has_split: bool = false

func _ready() -> void:
	if suppress_death_effect and owner is Enemy:
		owner.suppress_death_effect = true

func split() -> void:
	if has_split or not split_enemy_data or split_count <= 0:
		return
	has_split = true

	var spawner = get_tree().get_first_node_in_group("spawner") as Spawner
	if not spawner:
		push_error("[SplitOnDeathComponent] Spawner not found in group 'spawner'!")
		return

	var center_pos = owner.global_position

	for i in range(split_count):
		var spawn_pos: Vector2
		if max_radius > 0.0:
			var random_dir = Vector2.RIGHT.rotated(randf() * TAU)
			var dist = randf_range(min_radius, max_radius)
			spawn_pos = center_pos + (random_dir * dist)
		else:
			spawn_pos = center_pos

		spawner.spawn_split_enemy(spawn_pos, split_enemy_data)