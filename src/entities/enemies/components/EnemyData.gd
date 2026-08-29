class_name EnemyData extends Resource

@export_group("Identity")
@export var enemy_name: String
@export var enemy_scene: PackedScene

@export_group("Wave Director")
@export var spawn_cost: int = 1

@export_group("Rewards")
@export var enemy_score_reward: int = 100
@export var enemy_xp_reward: int = 25