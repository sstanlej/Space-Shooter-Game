class_name WeaponData extends Resource

@export var weapon_id: String = "blaster"
@export var weapon_name: String = "Standard Blaster"
@export var icon: Texture2D
@export var bullet_scene: PackedScene

@export var base_damage: float = 10.0
@export var base_attack_speed: float = 3.0
@export var base_bullet_speed: float = 400.0

@export var projectiles_per_shot: int = 1
@export var spread_angle_degrees: float = 0.0
@export var parallel_bullet_spacing: float = 6.0