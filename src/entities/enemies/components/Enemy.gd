class_name Enemy extends CharacterBody2D

var data: EnemyData

signal enemy_died(points: float, xp: float)
signal enemy_escaped

var direction: Vector2 = Vector2.LEFT
var move_speed: float = 30
var attack: float = 1

var is_escaping: bool = false

@onready var health_component: HealthComponent = $HealthComponent

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	move_speed = data.enemy_speed
	attack = data.enemy_damage
	if health_component:
		health_component.set_health(data.enemy_max_health)
		if not health_component.died.is_connected(_on_health_component_died):
			health_component.died.connect(_on_health_component_died)

func _physics_process(_delta: float) -> void:
	if position.x < -40 and not is_escaping:
		start_escape_sequence()
	elif not is_escaping:
		do_movement(_delta)

func start_escape_sequence() -> void:
	is_escaping = true
	enemy_escaped.emit()

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	for child in get_children():
		if child is CPUParticles2D or child is GPUParticles2D:
			child.emitting = false

	await get_tree().create_timer(1.5).timeout
	queue_free()

func do_movement(_delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()

func _on_health_component_died() -> void:
	spawn_death_effect()
	if data:
		enemy_died.emit(data.enemy_score_reward, data.enemy_xp_reward)
	queue_free()

func spawn_death_effect() -> void:
	if data and data.death_scene:
		var death_effect = data.death_scene.instantiate()
		get_parent().add_child(death_effect)
		death_effect.position = position
		GlobalAudio.play_crash()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_escaping:
		return

	var target = area
	if target.has_method("damage"):
		target.damage(attack)
		GlobalAudio.play_crash()

		enemy_escaped.emit()

		queue_free()