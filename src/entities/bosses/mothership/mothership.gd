class_name MothershipBoss extends Enemy

enum BossPhase {
	INTRO,
	IDLE,
	SPAWNING,
	ATTACKING,
	DEAD
}

@export_group("Boss State & Pacing")
var current_phase: BossPhase = BossPhase.INTRO
@export var phase_cooldown: float = 1.2

@export_group("Positions & Anchors")
@export var right_anchor_margin: float = 35.0
@export var spawn_phase_y: float = 45.0
@export var intro_duration: float = 2.0

@export_group("Attack Settings")
@export var projectile_scene: PackedScene
@export var attack_warning_scene: PackedScene
@export var attack_warning_duration: float = 0.3
@export var attack_warning_offset_x: float = -20.0
@export var min_attack_reps: int = 2
@export var max_attack_reps: int = 4
@export var projectiles_per_salvo: int = 5
@export var spread_angle_deg: float = 12.0
@export var track_duration: float = 0.5
@export var projectile_speed: float = 180.0
@export var shot_interval: float = 0.08
@export var salvo_interval: float = 0.75
@export var projectile_damage: float = 1.0

@export_group("Spawn Minions Settings")
@export var minion_enemy_data: EnemyData
@export var minions_per_phase: int = 3
@export var minion_eject_delay: float = 0.7
@export var minion_slide_distance: float = 55.0
@export var minion_slide_duration: float = 0.6

@export_group("Node References")
@export var beam_visual: CanvasItem
@export var spawn_point: Marker2D
@export var fire_point: Marker2D
@export var warning_component: WarningComponent

var player_ref: Node2D
var spawner_ref: Spawner
var enemies_container: Node2D
var projectiles_container: Node2D
var active_loop: bool = false
var default_x: float = 0.0

func _ready() -> void:
	super._ready()

	player_ref = get_tree().get_first_node_in_group("player") as Node2D

	spawner_ref = get_tree().get_first_node_in_group("spawner") as Spawner
	if not spawner_ref:
		var gm = get_tree().root.find_child("GameManager", true, false)
		if gm and gm.get("spawner"):
			spawner_ref = gm.spawner

	if not spawn_point:
		spawn_point = get_node_or_null("SpawnPoint")
	if not fire_point:
		fire_point = get_node_or_null("FirePoint")
	if not beam_visual:
		beam_visual = get_node_or_null("BeamSprite")
	if not warning_component:
		warning_component = get_node_or_null("WarningComponent")

	if beam_visual:
		beam_visual.visible = false

	has_entered_screen = false

func setup(enemy_data: EnemyData) -> void:
	super.setup(enemy_data)
	_start_boss_intro()

func _physics_process(_delta: float) -> void:
	pass

func _start_boss_intro() -> void:
	current_phase = BossPhase.INTRO
	var vp_size = get_viewport_rect().size
	default_x = vp_size.x - right_anchor_margin
	var target_intro_pos = Vector2(default_x, vp_size.y * 0.5)

	global_position = Vector2(vp_size.x + 80.0, vp_size.y * 0.5)

	if warning_component:
		await get_tree().create_timer(warning_component.warning_duration).timeout

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_intro_pos, intro_duration)
	await tween.finished

	has_entered_screen = true
	active_loop = true
	_run_boss_behavior_loop()

func _run_boss_behavior_loop() -> void:
	while active_loop and not is_queued_for_deletion():
		await _execute_attacking_phase()
		if not active_loop:
			break
		await get_tree().create_timer(phase_cooldown).timeout

		await _execute_spawning_phase()
		if not active_loop:
			break
		await get_tree().create_timer(phase_cooldown).timeout

func _execute_spawning_phase() -> void:
	current_phase = BossPhase.SPAWNING

	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(self, "global_position", Vector2(default_x, spawn_phase_y), 0.8)
	await move_tween.finished

	if beam_visual:
		beam_visual.visible = true
	GlobalAudio.play_beam()

	for i in range(minions_per_phase):
		if not active_loop:
			break
		_spawn_and_eject_minion()
		await get_tree().create_timer(minion_eject_delay).timeout

	await get_tree().create_timer(0.4).timeout

	if beam_visual:
		beam_visual.visible = false

	var return_tween = create_tween()
	return_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(self, "global_position:y", get_viewport_rect().size.y * 0.5, 0.7)
	await return_tween.finished

	current_phase = BossPhase.IDLE

func _spawn_and_eject_minion() -> void:
	if not minion_enemy_data or not minion_enemy_data.enemy_scene:
		return

	var minion = minion_enemy_data.enemy_scene.instantiate() as Enemy
	if not minion:
		return

	var container = spawner_ref.enemies_container if spawner_ref and spawner_ref.enemies_container else get_parent()
	container.add_child(minion)

	if spawner_ref:
		spawner_ref.active_enemies_count += 1
		spawner_ref.update_ui_enemies_left()
		if minion.has_signal("enemy_died"):
			minion.enemy_died.connect(spawner_ref._on_enemy_died)
		if minion.has_signal("enemy_escaped"):
			minion.enemy_escaped.connect(spawner_ref._on_enemy_escaped)

	var origin_pos = spawn_point.global_position if spawn_point else global_position + Vector2(0, 30)
	minion.global_position = origin_pos

	var minion_move_comp = minion.get_node_or_null("EnemyMovementComponent") as EnemyMovementComponent
	if minion_move_comp:
		minion_move_comp.can_move = false

	var hurtbox = minion.get_node_or_null("HurtboxComponent") as Area2D
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	minion.setup(minion_enemy_data)

	var target_eject_pos = origin_pos + Vector2(0, minion_slide_distance)
	var eject_tween = minion.create_tween()
	eject_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	eject_tween.tween_property(minion, "global_position", target_eject_pos, minion_slide_duration)

	eject_tween.finished.connect(func():
		if is_instance_valid(minion):
			if minion_move_comp:
				minion_move_comp.can_move = true
				minion_move_comp.on_enemy_setup()
			if hurtbox:
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)
	)

func _execute_attacking_phase() -> void:
	current_phase = BossPhase.ATTACKING
	var repetitions = randi_range(min_attack_reps, max_attack_reps)

	for r in range(repetitions):
		if not active_loop:
			break

		var target_y = global_position.y
		if is_instance_valid(player_ref):
			var vp_rect = get_viewport_rect()
			target_y = clampf(player_ref.global_position.y, 35.0, vp_rect.size.y - 35.0)

		var track_tween = create_tween()
		track_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		track_tween.tween_property(self, "global_position:y", target_y, track_duration)
		await track_tween.finished

		_spawn_attack_indicator()
		await get_tree().create_timer(attack_warning_duration).timeout

		await _fire_salvo()

		await get_tree().create_timer(salvo_interval).timeout

	current_phase = BossPhase.IDLE

func _spawn_attack_indicator() -> void:
	if not attack_warning_scene or not get_parent():
		return

	var indicator = attack_warning_scene.instantiate()
	get_parent().add_child(indicator)

	var base_pos = fire_point.global_position if fire_point else global_position
	var indicator_pos = Vector2(base_pos.x + attack_warning_offset_x, base_pos.y)
	indicator.global_position = indicator_pos

	if indicator.has_method("setup"):
		indicator.setup(attack_warning_duration, indicator_pos)

func _fire_salvo() -> void:
	var shoot_origin = fire_point.global_position if fire_point else global_position + Vector2(-30, 0)
	var proj_container = spawner_ref.projectiles_container if spawner_ref and spawner_ref.projectiles_container else get_parent()

	for p in range(projectiles_per_salvo):
		if not active_loop:
			break

		if projectile_scene and proj_container:
			var proj = projectile_scene.instantiate()
			proj_container.add_child(proj)
			proj.global_position = shoot_origin
			GlobalAudio.play_laser()

			var random_angle = deg_to_rad(randf_range(-spread_angle_deg, spread_angle_deg))
			var shoot_vector = Vector2.LEFT.rotated(random_angle)

			if proj.has_method("setup"):
				proj.setup(projectile_damage, projectile_speed, shoot_vector)
			elif "velocity" in proj:
				proj.velocity = shoot_vector * projectile_speed

		await get_tree().create_timer(shot_interval).timeout

func _on_health_component_died() -> void:
	active_loop = false
	current_phase = BossPhase.DEAD
	if beam_visual:
		beam_visual.visible = false
	super._on_health_component_died()
