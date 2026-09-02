class_name EnemyData extends Resource

enum SpawnOrigin {
	RIGHT_EDGE,    
	TOP_EDGE,      
	BOTTOM_EDGE,   
	RANDOM_EDGE    
}

@export_group("Visual & Base Stats")
@export var enemy_name: String = "Enemy"
@export var enemy_scene: PackedScene
@export var spawn_cost: int = 1
@export var spawn_origin: SpawnOrigin = SpawnOrigin.RIGHT_EDGE

@export_group("Rewards")
@export var enemy_score_reward: int = 100
@export var enemy_xp_reward: int = 25