class_name LocationData extends Resource

enum Rarity {
    COMMON = 0,
    UNCOMMON = 1,
    RARE = 2,
    EPIC = 3,
    LEGENDARY = 4
}

@export var location_id: int
@export var location_name: String
@export var location_rarity: Rarity

@export var spawnable_enemies: Array[EnemyData]

@export var background_texture: Texture2D
@export var middle_texture: Texture2D
@export var front_texture: Texture2D

