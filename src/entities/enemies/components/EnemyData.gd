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
@export var spawn_origin: SpawnOrigin = SpawnOrigin.RIGHT_EDGE
@export_range(0.1, 500.0, 0.1) var spawn_weight: float = 100.0

@export_group("Stats")
## HP przeciwnika ustawiane przy spawnie. 0 = zostaw wartość z HealthComponent w scenie
@export var max_health: int = 0

@export_group("Rewards")
@export var enemy_score_reward: int = 100
@export var enemy_xp_reward: int = 25

## Globalny mnożnik HP wszystkich przeciwników – na razie statyczny (1.0 = bez zmian).
## Gdy będzie gotowe skalowanie trudności, wystarczy zmienić EnemyData.health_multiplier.
static var health_multiplier: float = 1.0


## Końcowe HP przy spawnie: max_health × health_multiplier (0 = brak nadpisania)
func get_final_max_health() -> int:
	if max_health <= 0:
		return 0
	return maxi(1, int(round(max_health * health_multiplier)))