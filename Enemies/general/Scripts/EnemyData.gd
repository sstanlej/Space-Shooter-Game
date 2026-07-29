class_name EnemyData extends Resource

@export var enemy_id: int
@export var enemy_name: String
@export var enemy_scene: PackedScene

@export var enemy_max_health: int
@export var enemy_speed: float
@export var enemy_damage: int
@export var enemy_score_reward: int
@export var enemy_xp_reward: int

@export var enemy_weight: int

@export var death_scene: PackedScene

@export var split_enemy_data: EnemyData
@export var split_enemy_count: int
