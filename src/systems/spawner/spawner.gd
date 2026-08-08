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

@onready var spawn_timer: Timer = $SpawnTimer

var is_spawning: bool = false
var current_wave_budget: int = 0
var active_enemies_count: int = 0

func _ready() -> void:
	setup_timer()

func setup_timer() -> void:
	if not spawn_timer:
		spawn_timer = Timer.new()
		spawn_timer.name = "SpawnTimer"
		add_child(spawn_timer)

	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# --- KONTROLA FAL I SPAWNU ---

func start_spawning() -> void:
	is_spawning = true
	var wave_num = game_manager.current_wave if game_manager else 1

	current_wave_budget = base_wave_budget + (wave_num - 1) * budget_growth_per_wave
	active_enemies_count = 0

	print("[Spawner] Start fali ", wave_num, " | Budżet: ", current_wave_budget)

	schedule_next_spawn(0.2)

func stop_spawning() -> void:
	is_spawning = false
	if spawn_timer:
		spawn_timer.stop()

func pause_timers(should_pause: bool) -> void:
	if spawn_timer:
		spawn_timer.paused = should_pause

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

	if current_wave_budget > 0:
		var spawned = spawn_random_enemy_from_location()
		if spawned:
			schedule_next_spawn()
		else:
			schedule_next_spawn(1.0)

func spawn_random_enemy_from_location() -> bool:
	if not location_manager:
		return false

	var current_location: LocationData = location_manager.get_current_location()
	if not current_location or current_location.spawnable_enemies.size() == 0:
		return false

	var affordable_enemies: Array[EnemyData] = []
	for enemy_data in current_location.spawnable_enemies:
		if enemy_data and enemy_data.spawn_cost <= current_wave_budget:
			affordable_enemies.append(enemy_data)

	if affordable_enemies.size() == 0:
		current_wave_budget = 0
		check_wave_completion()
		return false

	var selected_enemy_data: EnemyData = affordable_enemies.pick_random()

	var viewport_rect = get_viewport().get_visible_rect()
	var spawn_x = viewport_rect.size.x + 40.0
	var spawn_y = randf_range(30.0, viewport_rect.size.y - 30.0)

	var enemy = spawn_enemy(Vector2(spawn_x, spawn_y), selected_enemy_data)
	if enemy:
		current_wave_budget -= selected_enemy_data.spawn_cost
		return true

	return false

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
	check_wave_completion()

func check_wave_completion() -> void:
	if current_wave_budget <= 0 and active_enemies_count == 0 and is_spawning:
		stop_spawning()
		print("[Spawner] Fala ukończona!")
		wave_completed.emit()

func kill_all_enemies() -> void:
	active_enemies_count = 0
	if enemies_container:
		for enemy in enemies_container.get_children():
			enemy.queue_free()