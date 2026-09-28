class_name Spawner extends Node

signal wave_completed

@export_group("System References")
@export var game_manager: GameManager
@export var progression_manager: ProgressionManager
@export var enemies_container: Node2D
@export var projectiles_container: Node2D

@export_group("Spawn Timing")
@export var base_min_spawn_delay: float = 0.8
@export var max_spawn_delay: float = 1.8
@export var delay_multiplier_per_wave: float = 0.96

@export_group("Fallback Settings")
@export var empty_wave_duration: float = 5.0

@onready var spawn_timer: Timer = $SpawnTimer
var fallback_timer: Timer

var is_spawning: bool = false
var active_enemies_count: int = 0
var unspawned_enemies: Array[EnemyData] = []
var current_wave_def: WaveDefinition = null
var current_custom_delay: float = -1.0
var _pending_boss_spawn: bool = false

func _ready() -> void:
	setup_timers()

func setup_timers() -> void:
	if not spawn_timer:
		spawn_timer = Timer.new()
		spawn_timer.name = "SpawnTimer"
		add_child(spawn_timer)

	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	fallback_timer = Timer.new()
	fallback_timer.name = "FallbackWaveTimer"
	fallback_timer.one_shot = true
	fallback_timer.timeout.connect(_on_fallback_timer_timeout)
	add_child(fallback_timer)

func start_spawning_wave(wave_def: WaveDefinition) -> void:
	is_spawning = true
	current_wave_def = wave_def
	active_enemies_count = 0
	unspawned_enemies.clear()
	_pending_boss_spawn = false
	current_custom_delay = -1.0

	if not wave_def:
		start_empty_wave_fallback()
		return

	current_custom_delay = wave_def.custom_spawn_delay

	if wave_def.boss_scene != null:
		_pending_boss_spawn = true

	# Jeśli fala ma tylko bossa:
	if wave_def.enemy_count <= 0 and _pending_boss_spawn:
		_pending_boss_spawn = false
		spawn_boss(wave_def.boss_scene, wave_def.boss_enemy_data)
		return

	# Budujemy kolejkę wrogów wg wag
	build_wave_queue(wave_def)

	if unspawned_enemies.size() > 0:
		schedule_next_spawn(0.3)
	elif _pending_boss_spawn:
		_pending_boss_spawn = false
		spawn_boss(wave_def.boss_scene, wave_def.boss_enemy_data)
	else:
		start_empty_wave_fallback()

func build_wave_queue(wave_def: WaveDefinition) -> void:
	unspawned_enemies.clear()
	var pool = wave_def.available_enemies.filter(func(e): return e != null and e.enemy_scene != null)
	if pool.is_empty():
		return

	var total_weight: float = 0.0
	for e in pool:
		total_weight += e.spawn_weight

	for i in range(wave_def.enemy_count):
		var roll = randf_range(0.0, total_weight)
		var cumulative: float = 0.0
		var chosen: EnemyData = pool[0]

		for e in pool:
			cumulative += e.spawn_weight
			if roll <= cumulative:
				chosen = e
				break
		unspawned_enemies.append(chosen)

	update_ui_enemies_left()

func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	if unspawned_enemies.size() > 0:
		var enemy_data = unspawned_enemies.pop_front()
		var spawn_pos = _calculate_spawn_position(enemy_data)
		spawn_enemy(spawn_pos, enemy_data)
		schedule_next_spawn(current_custom_delay)
	else:
		# Gdy wyczerpiemy miniony, sprawdzamy czy w tej fali czeka jeszcze boss
		if _pending_boss_spawn:
			_pending_boss_spawn = false
			spawn_boss(current_wave_def.boss_scene, current_wave_def.boss_enemy_data)
		else:
			check_wave_completion()

func _calculate_spawn_position(enemy_data: EnemyData) -> Vector2:
	var vp = get_viewport().get_visible_rect().size
	var origin = enemy_data.spawn_origin if enemy_data else EnemyData.SpawnOrigin.RIGHT_EDGE

	match origin:
		EnemyData.SpawnOrigin.RIGHT_EDGE:
			return Vector2(vp.x + 40.0, randf_range(30.0, vp.y - 30.0))
		EnemyData.SpawnOrigin.TOP_EDGE:
			return Vector2(randf_range(vp.x * 0.3, vp.x + 20.0), -40.0)
		EnemyData.SpawnOrigin.BOTTOM_EDGE:
			return Vector2(randf_range(vp.x * 0.3, vp.x + 20.0), vp.y + 40.0)
		EnemyData.SpawnOrigin.RANDOM_EDGE:
			var side = randi() % 3
			match side:
				0: return Vector2(vp.x + 40.0, randf_range(30.0, vp.y - 30.0))
				1: return Vector2(randf_range(vp.x * 0.3, vp.x), -40.0)
				_: return Vector2(randf_range(vp.x * 0.3, vp.x), vp.y + 40.0)

	return Vector2(vp.x + 40.0, vp.y * 0.5)

func spawn_enemy(spawn_position: Vector2, enemy_data: EnemyData) -> Enemy:
	if not enemy_data or not enemy_data.enemy_scene:
		return null

	var enemy_instance = enemy_data.enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		return null

	enemy_instance.global_position = spawn_position

	if enemies_container:
		enemies_container.add_child(enemy_instance)
	else:
		add_child(enemy_instance)

	if enemy_instance.has_method("setup"):
		enemy_instance.setup(enemy_data)

	active_enemies_count += 1
	update_ui_enemies_left()

	if enemy_instance.has_signal("enemy_died"):
		enemy_instance.enemy_died.connect(_on_enemy_died)
	if enemy_instance.has_signal("enemy_escaped"):
		enemy_instance.enemy_escaped.connect(_on_enemy_escaped)

	return enemy_instance

func spawn_split_enemy(spawn_position: Vector2, enemy_data: EnemyData) -> void:
	active_enemies_count += 1
	update_ui_enemies_left()
	call_deferred("_deferred_spawn_split_enemy", spawn_position, enemy_data)

func _deferred_spawn_split_enemy(spawn_position: Vector2, enemy_data: EnemyData) -> Enemy:
	if not enemy_data or not enemy_data.enemy_scene:
		active_enemies_count = maxi(0, active_enemies_count - 1)
		update_ui_enemies_left()
		check_wave_completion()
		return null

	var enemy_instance = enemy_data.enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		active_enemies_count = maxi(0, active_enemies_count - 1)
		update_ui_enemies_left()
		check_wave_completion()
		return null

	if enemies_container:
		enemies_container.add_child(enemy_instance)
	else:
		add_child(enemy_instance)

	enemy_instance.global_position = spawn_position

	if enemy_instance.has_method("setup"):
		enemy_instance.setup(enemy_data)

	if enemy_instance.has_signal("enemy_died"):
		enemy_instance.enemy_died.connect(_on_enemy_died)
	if enemy_instance.has_signal("enemy_escaped"):
		enemy_instance.enemy_escaped.connect(_on_enemy_escaped)

	return enemy_instance

func spawn_boss(boss_scene: PackedScene, boss_enemy_data: EnemyData) -> void:
	if not boss_scene:
		start_empty_wave_fallback()
		return

	var vp = get_viewport().get_visible_rect().size
	var spawn_pos = Vector2(vp.x + 60.0, vp.y * 0.5)
	var boss = spawn_enemy(spawn_pos, boss_enemy_data)

	if not boss:
		start_empty_wave_fallback()
		return

	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		ui_manager = get_tree().root.find_child("UIManager", true, false)

	if ui_manager and ui_manager.has_method("register_boss"):
		var health_comp = boss.get_node_or_null("HealthComponent") as HealthComponent
		var boss_name = boss_enemy_data.enemy_name if boss_enemy_data else "BOSS"
		if health_comp:
			ui_manager.register_boss(boss_name, health_comp)

func schedule_next_spawn(custom_delay: float = -1.0) -> void:
	if not is_spawning:
		return

	var delay = custom_delay if custom_delay > 0.0 else randf_range(base_min_spawn_delay, max_spawn_delay)
	spawn_timer.start(delay)

func _on_enemy_died(points: float, xp: float) -> void:
	if progression_manager:
		progression_manager.add_enemy_reward(points, xp)
	_on_enemy_removed()

func _on_enemy_escaped() -> void:
	if progression_manager and progression_manager.has_method("register_enemy_escaped"):
		progression_manager.register_enemy_escaped()
	_on_enemy_removed()

func _on_enemy_removed() -> void:
	active_enemies_count = maxi(0, active_enemies_count - 1)
	update_ui_enemies_left()
	check_wave_completion()

func check_wave_completion() -> void:
	if unspawned_enemies.is_empty() and active_enemies_count == 0 and not _pending_boss_spawn and is_spawning:
		if not game_manager or game_manager.is_player_alive:
			stop_spawning()
			print("[Spawner] Wave completed!")
			wave_completed.emit()

func start_empty_wave_fallback() -> void:
	update_ui_enemies_left()
	fallback_timer.start(empty_wave_duration)

func _on_fallback_timer_timeout() -> void:
	if is_spawning:
		stop_spawning()
		wave_completed.emit()

func stop_spawning() -> void:
	is_spawning = false
	if spawn_timer: spawn_timer.stop()
	if fallback_timer: fallback_timer.stop()

func pause_timers(should_pause: bool) -> void:
	if spawn_timer: spawn_timer.paused = should_pause
	if fallback_timer: fallback_timer.paused = should_pause

func update_ui_enemies_left() -> void:
	if game_manager and game_manager.ui_manager:
		if game_manager.ui_manager.has_method("update_enemies_left_label"):
			var boss_count = 1 if _pending_boss_spawn else 0
			game_manager.ui_manager.update_enemies_left_label(active_enemies_count + unspawned_enemies.size() + boss_count)
