class_name Spawner extends Node

signal wave_completed

@export_group("System References")
@export var game_manager: GameManager
@export var progression_manager: ProgressionManager
@export var location_manager: LocationManager
@export var enemies_container: Node2D
@export var projectiles_container: Node2D

@export_group("Wave Budget Settings")
@export var base_wave_budget: int = 10
@export var budget_growth_per_wave: int = 5

@export_group("Spawn Timing")
@export var base_min_spawn_delay: float = 0.8
@export var max_spawn_delay: float = 1.8
@export var delay_multiplier_per_wave: float = 0.95

@export_group("Fallback Settings")
@export var empty_wave_duration: float = 10.0

@onready var spawn_timer: Timer = $SpawnTimer
var fallback_timer: Timer

var is_spawning: bool = false
var current_wave_budget: int = 0
var active_enemies_count: int = 0

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

	# Timer awaryjny dla pustych lokacji (10 sekund przelotu)
	fallback_timer = Timer.new()
	fallback_timer.name = "FallbackWaveTimer"
	fallback_timer.one_shot = true
	fallback_timer.timeout.connect(_on_fallback_timer_timeout)
	add_child(fallback_timer)

# --- KONTROLA FAL I SPAWNU ---

func start_spawning() -> void:
	is_spawning = true
	var wave_num = game_manager.current_wave if game_manager else 1

	current_wave_budget = base_wave_budget + (wave_num - 1) * budget_growth_per_wave
	active_enemies_count = 0

	build_wave_queue(current_wave_budget)

	print("[Spawner] Start fali ", wave_num, " | Budżet: ", current_wave_budget)

	# Jeśli kolejka jest pusta (brak wrogów), fallback_timer już został odpalony w build_wave_queue
	if unspawned_enemies.size() > 0:
		schedule_next_spawn(0.2)

func build_wave_queue(budget: int) -> void:
	unspawned_enemies.clear()

	if not location_manager:
		start_empty_wave_fallback()
		return

	var current_location: LocationData = location_manager.get_current_location()
	if not current_location or current_location.spawnable_enemies.is_empty():
		print("[Spawner] Lokacja nie posiada wrogów! Uruchamiam spokojny przelot (", empty_wave_duration, "s)...")
		start_empty_wave_fallback()
		return

	var temp_budget = budget

	while temp_budget > 0:
		var affordable_enemies: Array[EnemyData] = []
		for enemy_data in current_location.spawnable_enemies:
			if enemy_data and enemy_data.spawn_cost <= temp_budget:
				affordable_enemies.append(enemy_data)

		if affordable_enemies.is_empty():
			break

		var picked_enemy = affordable_enemies.pick_random()
		unspawned_enemies.append(picked_enemy)
		temp_budget -= picked_enemy.spawn_cost

	if unspawned_enemies.is_empty():
		print("[Spawner] Brak wrogów mieszczących się w budżecie! Uruchamiam fallback...")
		start_empty_wave_fallback()
		return

	update_ui_enemies_left()

func start_empty_wave_fallback() -> void:
	update_ui_enemies_left()
	fallback_timer.start(empty_wave_duration)

func _on_fallback_timer_timeout() -> void:
	if is_spawning:
		print("[Spawner] Spokojny przelot zakończony!")
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

func schedule_next_spawn(custom_delay: float = -1.0) -> void:
	if not is_spawning or current_wave_budget <= 0:
		return
	var delay_multiplier = pow(delay_multiplier_per_wave, float(game_manager.current_wave - 1)) if game_manager else 1.0
	var delay = custom_delay if custom_delay > 0 else randf_range(base_min_spawn_delay * delay_multiplier, max_spawn_delay)
	spawn_timer.start(delay)

# --- SPAWNOWANIE PRZECIWNIKÓW ---

func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	if unspawned_enemies.size() > 0:
		var spawned = spawn_next_enemy_from_queue()
		if spawned:
			schedule_next_spawn()
		else:
			schedule_next_spawn(1.0)

func spawn_next_enemy_from_queue() -> bool:
	if unspawned_enemies.size() == 0:
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

# --- OBSŁUGA ŚMIERCI / UCIECZKI WROGA ---

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
	if unspawned_enemies.size() == 0 and active_enemies_count == 0 and is_spawning and game_manager.is_player_alive:
		stop_spawning()
		print("[Spawner] Fala ukończona!")
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