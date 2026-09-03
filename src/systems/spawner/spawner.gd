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
var current_wave_config: WaveConfig = null
var unspawned_enemies: Array[EnemyData] = []
var current_event_delay: float = -1.0

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

# --- START FALI ---

func start_spawning_wave(config: WaveConfig) -> void:
	is_spawning = true
	current_wave_config = config
	active_enemies_count = 0
	unspawned_enemies.clear()
	current_event_delay = -1.0

	if not config:
		start_empty_wave_fallback()
		return

	var loc_name = config.location.location_name if config.location else "None"
	print("\n[Spawner] >>> Wave %d [%s] | Location: '%s' | Budget: %d" % [
		config.wave_number, config.get_type_string(), loc_name, config.wave_budget
	])

	match config.wave_type:
		WaveConfig.WaveType.STANDARD:
			build_standard_wave_queue(config.wave_budget, config.location)
			_start_queue_if_ready()

		WaveConfig.WaveType.EVENT:
			build_event_queue(config)
			_start_queue_if_ready()

		WaveConfig.WaveType.BOSS:
			spawn_boss(config.boss_scene, config.boss_enemy_data)

func _start_queue_if_ready() -> void:
	if unspawned_enemies.size() > 0:
		log_enemy_composition(unspawned_enemies)
		schedule_next_spawn(0.3)
	else:
		start_empty_wave_fallback()

# --- BUDOWANIE KOLEJEK ---

func build_standard_wave_queue(budget: int, location: LocationData) -> void:
	if not location or location.spawnable_enemies.is_empty():
		return

	var temp_budget = budget
	while temp_budget > 0:
		var affordable = location.spawnable_enemies.filter(func(e): return e and e.spawn_cost <= temp_budget)
		if affordable.is_empty():
			break
		var picked: EnemyData = affordable.pick_random()
		unspawned_enemies.append(picked)
		temp_budget -= picked.spawn_cost

	update_ui_enemies_left()

func build_event_queue(config: WaveConfig) -> void:
	unspawned_enemies.clear()

	var ev = config.event_data
	if not ev or ev.event_enemies.is_empty():
		print("[Spawner] Event configuration is missing or has no enemies! Starting standard fallback...")
		build_standard_wave_queue(config.wave_budget, config.location)
		return

	current_event_delay = ev.spawn_delay

	for i in range(ev.spawn_count):
		var picked = ev.event_enemies.pick_random()
		if picked:
			unspawned_enemies.append(picked)

	update_ui_enemies_left()

# --- SPAWNOWANIE I POZYCJONOWANIE ---

func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	if unspawned_enemies.size() > 0:
		var enemy_data = unspawned_enemies.pop_front()
		var spawn_pos = _calculate_spawn_position(enemy_data)
		spawn_enemy(spawn_pos, enemy_data)
		schedule_next_spawn(current_event_delay)
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
			return _calculate_spawn_position_random(vp)

	return Vector2(vp.x + 40.0, vp.y * 0.5)

func _calculate_spawn_position_random(vp: Vector2) -> Vector2:
	var side = randi() % 3
	match side:
		0: return Vector2(vp.x + 40.0, randf_range(30.0, vp.y - 30.0))
		1: return Vector2(randf_range(vp.x * 0.3, vp.x), -40.0)
		_: return Vector2(randf_range(vp.x * 0.3, vp.x), vp.y + 40.0)

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

# --- ENEMY SPLITTING (SplitOnDeathComponent) ---

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

# --- BOSS SPAWN ---

func spawn_boss(boss_scene: PackedScene, boss_enemy_data: EnemyData) -> void:
	if not boss_scene:
		start_empty_wave_fallback()
		return

	var vp = get_viewport().get_visible_rect().size
	var spawn_pos = Vector2(vp.x + 60.0, vp.y * 0.5)
	var boss = spawn_enemy(spawn_pos, boss_enemy_data)
	if not boss:
		start_empty_wave_fallback()

# --- CYKL ŻYCIA I TIMERY ---

func schedule_next_spawn(custom_delay: float = -1.0) -> void:
	if not is_spawning:
		return

	var wave_idx = current_wave_config.wave_number if current_wave_config else 1
	var delay_multiplier = pow(delay_multiplier_per_wave, float(wave_idx - 1))
	var delay = custom_delay if custom_delay > 0 else randf_range(base_min_spawn_delay * delay_multiplier, max_spawn_delay)

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
	if unspawned_enemies.is_empty() and active_enemies_count == 0 and is_spawning:
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
			game_manager.ui_manager.update_enemies_left_label(active_enemies_count + unspawned_enemies.size())

func log_enemy_composition(enemies_list: Array) -> void:
	var counts: Dictionary = {}
	for item in enemies_list:
		var e_name = item.enemy_name if (item is EnemyData and not item.enemy_name.is_empty()) else "Enemy"
		counts[e_name] = counts.get(e_name, 0) + 1
	var parts: Array[String] = []
	for k in counts.keys():
		parts.append("%dx %s" % [counts[k], k])
	print("[Spawner] Total enemies: %d | Composition: %s" % [enemies_list.size(), ", ".join(parts)])
