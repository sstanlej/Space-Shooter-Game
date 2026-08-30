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

# --- WAVE START VIA WAVECONFIG ---

func start_spawning_wave(config: WaveConfig) -> void:
	is_spawning = true
	current_wave_config = config
	active_enemies_count = 0
	unspawned_enemies.clear()

	if not config:
		start_empty_wave_fallback()
		return

	# 1. Log wave header first with leading newline
	var extra_label = " [Event: %s]" % config.event_id if config.wave_type == WaveConfig.WaveType.EVENT else ""
	var loc_name = config.location.location_name if config.location else "None"
	print("\n[Spawner] >>> Wave %d [%s%s] | Location: '%s' | Budget: %d" % [
		config.wave_number,
		config.get_type_string(),
		extra_label,
		loc_name,
		config.wave_budget
	])

	# 2. Build queues and handle spawns
	match config.wave_type:
		WaveConfig.WaveType.STANDARD:
			build_standard_wave_queue(config.wave_budget, config.location)
			if unspawned_enemies.size() > 0:
				log_enemy_composition(unspawned_enemies)
				schedule_next_spawn(0.3)

		WaveConfig.WaveType.EVENT:
			build_event_queue(config.event_id, config.location)
			if unspawned_enemies.size() > 0:
				log_enemy_composition(unspawned_enemies)
				schedule_next_spawn(0.3)

		WaveConfig.WaveType.BOSS:
			spawn_boss(config.boss_scene, config.boss_enemy_data)

# --- QUEUE GENERATION ---

func build_standard_wave_queue(budget: int, location: LocationData) -> void:
	unspawned_enemies.clear()

	if not location or location.spawnable_enemies.is_empty():
		print("[Spawner] Location has no spawnable enemies! Starting peaceful fallback flight...")
		start_empty_wave_fallback()
		return

	var temp_budget = budget
	while temp_budget > 0:
		var affordable_enemies = location.spawnable_enemies.filter(func(e): return e and e.spawn_cost <= temp_budget)
		if affordable_enemies.is_empty():
			break

		var picked_enemy: EnemyData = affordable_enemies.pick_random()
		unspawned_enemies.append(picked_enemy)
		temp_budget -= picked_enemy.spawn_cost

	if unspawned_enemies.is_empty():
		print("[Spawner] Wave budget is too low for any enemy! Starting peaceful fallback flight...")
		start_empty_wave_fallback()
		return

	update_ui_enemies_left()

func build_event_queue(event_id: String, location: LocationData) -> void:
	unspawned_enemies.clear()

	match event_id:
		"meteor_shower":
			var candidates = location.spawnable_enemies.filter(
				func(e): return e and "meteor" in e.enemy_name.to_lower()
			) if location else []

			var meteor_data: EnemyData = null
			if not candidates.is_empty():
				var big_meteors = candidates.filter(func(e): return "big" in e.enemy_name.to_lower())
				meteor_data = big_meteors[0] if not big_meteors.is_empty() else candidates[0]
			elif location and not location.spawnable_enemies.is_empty():
				meteor_data = location.spawnable_enemies[0]

			if meteor_data:
				for i in range(10):
					unspawned_enemies.append(meteor_data)
			else:
				print("[Spawner] No suitable hazard enemy found for event '%s'!" % event_id)
				start_empty_wave_fallback()
				return

		_:
			build_standard_wave_queue(15, location)

	update_ui_enemies_left()

func spawn_boss(boss_scene: PackedScene, boss_enemy_data: EnemyData) -> void:
	if not boss_scene:
		print("[Spawner] Missing Boss scene in Act configuration! Starting fallback...")
		start_empty_wave_fallback()
		return

	var boss_name = boss_enemy_data.enemy_name if boss_enemy_data else "Boss"
	print("[Spawner] Boss encounter initialized: 1x %s" % boss_name)

	var boss_instance = boss_scene.instantiate() as Enemy
	if not boss_instance:
		start_empty_wave_fallback()
		return

	var viewport_rect = get_viewport().get_visible_rect()
	var spawn_pos = Vector2(viewport_rect.size.x + 60.0, viewport_rect.size.y * 0.5)

	if enemies_container:
		enemies_container.add_child(boss_instance)
	else:
		add_child(boss_instance)

	boss_instance.global_position = spawn_pos

	if boss_instance.has_method("setup") and boss_enemy_data:
		boss_instance.setup(boss_enemy_data)

	active_enemies_count = 1
	update_ui_enemies_left()

	if boss_instance.has_signal("enemy_died"):
		boss_instance.enemy_died.connect(_on_enemy_died)
	if boss_instance.has_signal("enemy_escaped"):
		boss_instance.enemy_escaped.connect(_on_enemy_escaped)

# --- SPAWN TIMING & EXECUTION ---

func schedule_next_spawn(custom_delay: float = -1.0) -> void:
	if not is_spawning:
		return

	var wave_idx = current_wave_config.wave_number if current_wave_config else 1
	var delay_multiplier = pow(delay_multiplier_per_wave, float(wave_idx - 1))
	var delay = custom_delay if custom_delay > 0 else randf_range(base_min_spawn_delay * delay_multiplier, max_spawn_delay)

	if current_wave_config and current_wave_config.wave_type == WaveConfig.WaveType.EVENT:
		delay = 1.1

	spawn_timer.start(delay)

func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	if unspawned_enemies.size() > 0:
		var spawned = spawn_next_enemy_from_queue()
		if spawned:
			schedule_next_spawn()
		else:
			schedule_next_spawn(0.8)
	else:
		check_wave_completion()

func spawn_next_enemy_from_queue() -> bool:
	if unspawned_enemies.is_empty():
		check_wave_completion()
		return false

	var selected_enemy_data: EnemyData = unspawned_enemies.pop_front()

	var viewport_rect = get_viewport().get_visible_rect()
	var spawn_x = viewport_rect.size.x + 40.0
	var spawn_y = randf_range(30.0, viewport_rect.size.y - 30.0)

	var enemy = spawn_enemy(Vector2(spawn_x, spawn_y), selected_enemy_data)
	return enemy != null

func spawn_enemy(spawn_position: Vector2, enemy_data: EnemyData) -> Enemy:
	if not enemy_data or not enemy_data.enemy_scene:
		return null

	var enemy_instance = enemy_data.enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		return null

	if enemies_container:
		enemies_container.add_child(enemy_instance)
	else:
		add_child(enemy_instance)

	enemy_instance.global_position = spawn_position

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
		active_enemies_count = max(0, active_enemies_count - 1)
		update_ui_enemies_left()
		check_wave_completion()
		return null

	var enemy_instance = enemy_data.enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		active_enemies_count = max(0, active_enemies_count - 1)
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

# --- EMPTY ZONE FALLBACK ---

func start_empty_wave_fallback() -> void:
	update_ui_enemies_left()
	fallback_timer.start(empty_wave_duration)

func _on_fallback_timer_timeout() -> void:
	if is_spawning:
		stop_spawning()
		wave_completed.emit()

func stop_spawning() -> void:
	is_spawning = false
	if spawn_timer:
		spawn_timer.stop()
	if fallback_timer:
		fallback_timer.stop()

func pause_timers(should_pause: bool) -> void:
	if spawn_timer:
		spawn_timer.paused = should_pause
	if fallback_timer:
		fallback_timer.paused = should_pause

# --- ENEMY LIFECYCLE & WAVE COMPLETION ---

func _on_enemy_died(points: float, xp: float) -> void:
	if progression_manager:
		progression_manager.add_enemy_reward(points, xp)
	_on_enemy_removed()

func _on_enemy_escaped() -> void:
	if progression_manager and progression_manager.has_method("register_enemy_escaped"):
		progression_manager.register_enemy_escaped()
	_on_enemy_removed()

func _on_enemy_removed() -> void:
	active_enemies_count = max(0, active_enemies_count - 1)
	update_ui_enemies_left()
	check_wave_completion()

func check_wave_completion() -> void:
	if unspawned_enemies.is_empty() and active_enemies_count == 0 and is_spawning:
		if not game_manager or game_manager.is_player_alive:
			stop_spawning()
			print("[Spawner] Wave completed!")
			wave_completed.emit()

func kill_all_enemies() -> void:
	active_enemies_count = 0
	if fallback_timer:
		fallback_timer.stop()
	if enemies_container:
		for enemy in enemies_container.get_children():
			enemy.queue_free()

func get_total_remaining_enemies() -> int:
	return active_enemies_count + unspawned_enemies.size()

func update_ui_enemies_left() -> void:
	if game_manager and game_manager.ui_manager:
		if game_manager.ui_manager.has_method("update_enemies_left_label"):
			game_manager.ui_manager.update_enemies_left_label(get_total_remaining_enemies())

# --- CONSOLE LOGGING ---

func log_enemy_composition(enemies_list: Array) -> void:
	if enemies_list.is_empty():
		return

	var counts: Dictionary = {}
	for item in enemies_list:
		var e_name = item.enemy_name if (item is EnemyData and not item.enemy_name.is_empty()) else "Enemy"
		counts[e_name] = counts.get(e_name, 0) + 1

	var parts: Array[String] = []
	for k in counts.keys():
		parts.append("%dx %s" % [counts[k], k])

	print("[Spawner] Total enemies: %d | Composition: %s" % [enemies_list.size(), ", ".join(parts)])