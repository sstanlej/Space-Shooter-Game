class_name Spawner extends Node

@export_group("System References")
@export var game_manager: GameManager
@export var progression_manager: ProgressionManager
@export var location_manager: LocationManager
@export var enemies_container: Node2D
@export var projectiles_container: Node2D

@export_group("Spawn Settings")
@export var base_spawn_interval: float = 2.0
@export var wave_duration: float = 15.0 # Czas trwania fali w sekundach

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

var is_spawning: bool = false
var difficulty_multiplier: float = 1.0
var difficulty_wave_gain: float = 0.1 # Wzrost trudności na falę (15% na falę)

func _ready() -> void:
	setup_timers()

func setup_timers() -> void:
	if not spawn_timer:
		spawn_timer = Timer.new()
		spawn_timer.name = "SpawnTimer"
		add_child(spawn_timer)

	if not wave_timer:
		wave_timer = Timer.new()
		wave_timer.name = "WaveTimer"
		add_child(wave_timer)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	wave_timer.timeout.connect(_on_wave_timer_timeout)

# --- KONTROLA FAL I SPAWNU ---

func start_spawning() -> void:
	is_spawning = true

	var current_wave = game_manager.current_wave if game_manager else 1
	adjust_difficulty(current_wave)

	wave_timer.start(wave_duration)
	spawn_timer.start(get_adjusted_spawn_interval())
	print("[Spawner] Start spawnowania dla fali: ", current_wave)

func stop_spawning() -> void:
	is_spawning = false
	spawn_timer.stop()
	wave_timer.stop()
	print("[Spawner] Zatrzymano spawnowanie")

func adjust_difficulty(wave_number: int) -> void:
	difficulty_multiplier = 1.0 + (wave_number - 1) * difficulty_wave_gain
	print("[Spawner] Zmieniono trudność dla fali ", wave_number, ": multiplier = ", difficulty_multiplier)

func get_adjusted_spawn_interval() -> float:
	return max(0.4, base_spawn_interval / difficulty_multiplier)

# --- OBSŁUGA TIMERA I INSTANCJOWANIE WROGA ---

func pause_timers(should_pause: bool) -> void:
	if spawn_timer:
		spawn_timer.paused = should_pause
	if wave_timer:
		wave_timer.paused = should_pause

func _on_spawn_timer_timeout() -> void:
	if not is_spawning:
		return

	spawn_random_enemy_from_location()

func spawn_random_enemy_from_location() -> void:
	if not location_manager:
		print("[Spawner] Brak przypiętego LocationManagera!")
		return

	var current_location: LocationData = location_manager.get_current_location()
	if not current_location or current_location.spawnable_enemies.size() == 0:
		print("[Spawner] Aktualna lokacja nie posiada zdefiniowanych wrogów!")
		return

	# 1. Losujemy EnemyData z lokacji
	var selected_enemy_data: EnemyData = current_location.spawnable_enemies.pick_random()

	# 2. Obliczamy pozycję spawnu poza prawą krawędzią ekranu
	var viewport_rect = get_viewport().get_visible_rect()
	var spawn_x = viewport_rect.size.x + 40.0
	var spawn_y = randf_range(30.0, viewport_rect.size.y - 30.0)
	var spawn_pos = Vector2(spawn_x, spawn_y)

	# 3. Wywołujemy uniwersalną funkcję spawn_enemy!
	spawn_enemy(spawn_pos, selected_enemy_data)

# Główna, uniwersalna funkcja tworzenia wroga (REUSABLE)
func spawn_enemy(spawn_position: Vector2, enemy_data: EnemyData) -> Enemy:
	if not enemy_data or not enemy_data.enemy_scene:
		print("[Spawner] Błąd: Brak danych lub sceny dla spawn_enemy!")
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

	if enemy_instance.has_signal("enemy_died"):
		enemy_instance.enemy_died.connect(_on_enemy_died)

	return enemy_instance

func _on_wave_timer_timeout() -> void:
	stop_spawning()
	if game_manager:
		game_manager.finish_wave()

func _on_enemy_died(points: float, xp: float) -> void:
	if progression_manager:
		progression_manager.add_enemy_reward(points, xp)

func kill_all_enemies() -> void:
	if enemies_container:
		for enemy in enemies_container.get_children():
			enemy.queue_free()
