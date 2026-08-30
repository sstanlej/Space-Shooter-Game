class_name ActData extends Resource

@export_group("Act Identity")
@export var act_index: int = 1
@export var act_name: String = "Act I"

@export_group("Progression")
@export var locations: Array[LocationData] = []
@export var waves_per_location: int = 3

@export_group("Boss Encounter")
@export var boss_scene: PackedScene
@export var boss_enemy_data: EnemyData