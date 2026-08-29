class_name Enemy extends CharacterBody2D

signal enemy_died(points: float, xp: float)
signal enemy_escaped

@export_group("Visual Effects")
@export var death_scene: PackedScene

var data: EnemyData
var is_escaping: bool = false
var is_intangible: bool = false
var suppress_death_effect: bool = false

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var movement_component: EnemyMovementComponent = get_node_or_null("EnemyMovementComponent")

var visual_nodes: Array[CanvasItem] = []
var flash_tween: Tween

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	find_visual_nodes(self)
	for visual in visual_nodes:
		if visual.material:
			visual.material = visual.material.duplicate()

	if health_component:
		if not health_component.damage_taken.is_connected(_on_damage_taken):
			health_component.damage_taken.connect(_on_damage_taken)

func find_visual_nodes(parent: Node) -> void:
	for child in parent.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			visual_nodes.append(child)
		if child.get_child_count() > 0:
			find_visual_nodes(child)

func setup(enemy_data: EnemyData) -> void:
	if not enemy_data:
		return

	data = enemy_data

	# Jeśli wróg nie posiada HealthComponent (np. Spectator), staje się nietykalny
	is_intangible = (health_component == null)

	if is_intangible:
		setup_intangible_state()
	else:
		setup_mortal_state()

	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

	for child in get_children():
		if child.has_method("on_enemy_setup"):
			child.on_enemy_setup()

func setup_intangible_state() -> void:
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

func setup_mortal_state() -> void:
	if health_component:
		if not health_component.died.is_connected(_on_health_component_died):
			health_component.died.connect(_on_health_component_died)

func _physics_process(delta: float) -> void:
	if position.x < -40.0 and not is_escaping:
		start_escape_sequence()
	elif not is_escaping and movement_component:
		movement_component.move(delta)

func _on_damage_taken(_amount: int = 0) -> void:
	if not is_intangible:
		trigger_hit_flash()
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_enemy_hit"):
			GlobalAudio.play_enemy_hit()

func trigger_hit_flash() -> void:
	if visual_nodes.is_empty():
		return
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	for visual in visual_nodes:
		if visual.material and visual.material is ShaderMaterial:
			visual.material.set_shader_parameter("active", true)
		else:
			visual.modulate = Color(4.0, 4.0, 4.0, 1.0)

	flash_tween = create_tween()
	flash_tween.tween_interval(0.07)
	flash_tween.tween_callback(func():
		for visual in visual_nodes:
			if not is_instance_valid(visual):
				continue
			if visual.material and visual.material is ShaderMaterial:
				visual.material.set_shader_parameter("active", false)
			else:
				visual.modulate = Color.WHITE
	)

func start_escape_sequence() -> void:
	is_escaping = true
	enemy_escaped.emit()

	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
		elif child is CPUParticles2D or child is GPUParticles2D:
			child.emitting = false

	await get_tree().create_timer(1.5).timeout
	queue_free()

func die_by_collision() -> void:
	if is_escaping or is_intangible:
		return
	enemy_escaped.emit()
	queue_free()

func _on_health_component_died() -> void:
	if is_intangible:
		return
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	var split_comp = get_node_or_null("SplitOnDeathComponent")
	if split_comp and split_comp.has_method("split"):
		split_comp.split()

	if not suppress_death_effect:
		spawn_death_effect()

	if data:
		enemy_died.emit(data.enemy_score_reward, data.enemy_xp_reward)
	queue_free()

func spawn_death_effect() -> void:
	if death_scene:
		var effect = death_scene.instantiate()
		if get_parent():
			get_parent().add_child(effect)
		effect.position = position
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_crash"):
			GlobalAudio.play_crash()