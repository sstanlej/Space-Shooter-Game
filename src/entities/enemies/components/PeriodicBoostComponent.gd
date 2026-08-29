class_name PeriodicBoostComponent extends Node

@export var boost_speed_mult: float = 2.0
@export var min_boost_interval: float = 2.0
@export var max_boost_interval: float = 5.0
@export var boost_duration: float = 1.5

@export_group("Visual Swap")
@export var target_sprite: Sprite2D
@export var normal_texture: Texture2D
@export var boost_texture: Texture2D

var movement_comp: EnemyMovementComponent

func _ready() -> void:
	movement_comp = owner.get_node_or_null("EnemyMovementComponent")
	if not target_sprite and owner:
		target_sprite = owner.get_node_or_null("Sprite2D")
	schedule_boost()

func schedule_boost() -> void:
	var wait_time = randf_range(min_boost_interval, max_boost_interval)
	get_tree().create_timer(wait_time).timeout.connect(start_boost)

func start_boost() -> void:
	if not is_instance_valid(owner) or not movement_comp:
		return

	movement_comp.speed_multiplier = boost_speed_mult
	if target_sprite and boost_texture:
		target_sprite.texture = boost_texture

	get_tree().create_timer(boost_duration).timeout.connect(stop_boost)

func stop_boost() -> void:
	if not is_instance_valid(owner) or not movement_comp:
		return

	movement_comp.speed_multiplier = 1.0
	if target_sprite and normal_texture:
		target_sprite.texture = normal_texture

	schedule_boost()