class_name HealthComponent extends Node

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal healed(amount: int)
signal died

@export_group("Health Settings")
@export var max_health: int = 100
var current_health: int

@export_group("Floating Damage Numbers")
@export var show_damage_numbers: bool = true
@export var damage_number_scene: PackedScene = preload("res://src/ui/floating_damage_number.tscn")
@export var damage_number_offset: Vector2 = Vector2(0, -12.0)

func _ready() -> void:
	current_health = max_health

func set_max_health(new_max: int) -> void:
	max_health = max(1, new_max)
	current_health = clampi(current_health, 1, max_health)
	health_changed.emit(current_health, max_health)

func set_health(new_health: int) -> void:
	max_health = max(1, new_health)
	current_health = clampi(new_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func heal(amount: int) -> void:
	if current_health >= max_health or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func take_damage(amount: int, damage_type: int = 0) -> void:
	if current_health <= 0 or amount <= 0:
		return

	current_health -= amount
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)

	if show_damage_numbers:
		_spawn_damage_number(amount, damage_type)
	
	if current_health <= 0:
		current_health = 0
		died.emit()

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return current_health

func _spawn_damage_number(amount: int, damage_type: int) -> void:
	if not damage_number_scene:
		return

	var number_node = damage_number_scene.instantiate() as FloatingDamageNumber
	if not number_node:
		return

	# Szukamy niezależnego kontenera w świecie
	var spawn_parent = get_tree().get_first_node_in_group("projectiles_container")
	if not spawn_parent:
		spawn_parent = get_tree().current_scene

	var base_pos = owner.global_position if owner else (get_parent() as Node2D).global_position
	number_node.global_position = base_pos + damage_number_offset

	spawn_parent.add_child(number_node)
	number_node.setup(amount, damage_type as FloatingDamageNumber.DamageType)
