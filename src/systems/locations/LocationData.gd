class_name LocationData extends Resource

enum Rarity {
	COMMON,
	RARE,
	SPECIAL
}

@export_group("Identity")
@export var location_id: String = "space"
@export var location_name: String = "Deep Space"
@export var location_rarity: Rarity = Rarity.COMMON

@export_group("Waves Progression")
@export var waves: Array[WaveDefinition] = []

@export_group("Visuals (Parallax Layers)")
@export var background_texture: Texture2D
@export var middle_texture: Texture2D
@export var front_texture: Texture2D
