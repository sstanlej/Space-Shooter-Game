class_name WaveDefinition extends Resource

@export_group("Enemy Spawning")
@export var enemy_count: int = 12
@export var available_enemies: Array[EnemyData] = []
@export var custom_spawn_delay: float = -1.0

@export_group("Boss (Optional)")
@export var boss_scene: PackedScene
@export var boss_enemy_data: EnemyData

@export_group("Custom Banner (Optional)")
@export var banner_title: String = ""
@export var banner_subtitle: String = ""