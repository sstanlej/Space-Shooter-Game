class_name LocationData extends Resource

enum Rarity {
	COMMON,   ## Basic Campaign Locations
	RARE,     ## Harder Locations in Endless Mode
	SPECIAL   ## Special Locations in Endless Mode
}

@export_group("Identity")
@export var location_id: String = "space"
@export var location_name: String = "Deep Space"
@export var location_rarity: Rarity = Rarity.COMMON

@export_group("Flow & Rules")
@export_range(0, 5, 1) var custom_wave_count: int = 0

@export_group("Spawning Pool")
@export var spawnable_enemies: Array[EnemyData] = []

@export_group("Events")
@export var available_events: Array[WaveEventData] = []

@export_group("Visuals (Parallax Layers)")
@export var background_texture: Texture2D
@export var middle_texture: Texture2D
@export var front_texture: Texture2D