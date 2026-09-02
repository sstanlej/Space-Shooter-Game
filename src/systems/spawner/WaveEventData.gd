class_name WaveEventData extends Resource

@export_group("Identity & UI")
@export var event_id: String = "event_default"
@export var event_name: String = "SPACE HAZARD"
@export var banner_title: String = "[color=crimson]HAZARD DETECTED[/color]"
@export var banner_subtitle: String = "[color=gold]Survive the event![/color]"

@export_group("Spawning Rules")
@export var event_enemies: Array[EnemyData] = []
@export var spawn_count: int = 15
@export var spawn_delay: float = 0.5
@export var batch_size: int = 1