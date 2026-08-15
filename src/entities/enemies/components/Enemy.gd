class_name Enemy extends CharacterBody2D

signal enemy_died(points: float, xp: float)
signal enemy_escaped

var data: EnemyData

var direction: Vector2 = Vector2.LEFT
var move_speed: float = 30.0
var attack: float = 1.0

var is_escaping: bool = false
var is_intangible: bool = false

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")

var visual_nodes: Array[CanvasItem] = []
var flash_tween: Tween

func _ready() -> void:
	find_visual_nodes(self)
	for visual in visual_nodes:
		if visual.material:
			visual.material = visual.material.duplicate()

	if health_component:
		if not health_component.damage_taken.is_connected(_on_damage_taken):
			health_component.damage_taken.connect(_on_damage_taken)

func find_visual_nodes(parent: Node) -> void:
	for child in parent.get_children():
		# Zbieramy zarówno zwykłe Sprite2D, jak i animowane AnimatedSprite2D
		if child is Sprite2D or child is AnimatedSprite2D:
			visual_nodes.append(child)
		# Jeśli sprite jest schowany głębiej (np. w węźle Visuals / Pivot), szukamy rekurencyjnie:
		if child.get_child_count() > 0:
			find_visual_nodes(child)

func setup(enemy_data: EnemyData) -> void:
	if not enemy_data:
		return

	data = enemy_data
	move_speed = data.enemy_speed
	attack = data.enemy_damage
	
	# Jeśli max HP <= 0, wróg staje się niematerialnym/nieśmiertelnym bytem
	is_intangible = data.enemy_max_health <= 0

	if is_intangible:
		setup_intangible_state()
	else:
		setup_mortal_state()

	# Aktywacja emiterów cząsteczek (silniki, ogień, dym)
	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

func setup_intangible_state() -> void:
	# Wyłączenie fizyki i hitboxów dla bytów eterycznych (np. Spectator)
	collision_layer = 0
	collision_mask = 0

	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

func setup_mortal_state() -> void:
	if health_component:
		health_component.set_health(int(data.enemy_max_health))
		if not health_component.died.is_connected(_on_health_component_died):
			health_component.died.connect(_on_health_component_died)

func _physics_process(_delta: float) -> void:
	if position.x < -40.0 and not is_escaping:
		start_escape_sequence()
	elif not is_escaping:
		do_movement(_delta)

func do_movement(_delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()

# --- EFEKT BIAŁEGO BŁYSKU (HIT FLASH) ---

func _on_damage_taken(_amount: int = 0) -> void:
	if not is_intangible:
		trigger_hit_flash()
		GlobalAudio.play_enemy_hit()

func trigger_hit_flash() -> void:
	if visual_nodes.is_empty():
		return

	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	# Błysk dla WSZYSTKICH spritów wroga naraz
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
# --- ŚMIERĆ, UCIECZKA I KOLIZJE ---

func start_escape_sequence() -> void:
	is_escaping = true
	enemy_escaped.emit()

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
		elif child is CPUParticles2D or child is GPUParticles2D:
			child.emitting = false

	await get_tree().create_timer(1.5).timeout
	queue_free()

func _on_health_component_died() -> void:
	if is_intangible:
		return

	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	spawn_death_effect()
	if data:
		enemy_died.emit(data.enemy_score_reward, data.enemy_xp_reward)
	queue_free()

func spawn_death_effect() -> void:
	if data and data.death_scene:
		var death_effect = data.death_scene.instantiate()
		if get_parent():
			get_parent().add_child(death_effect)
		death_effect.position = position
		
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_crash"):
			GlobalAudio.play_crash()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_escaping or is_intangible:
		return

	var target = area
	if target.has_method("damage"):
		target.damage(attack)
		
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_crash"):
			GlobalAudio.play_crash()

		enemy_escaped.emit()
		queue_free()