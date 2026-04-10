class_name GameManager extends Node2D

@onready var player: Player = $"../Player"
@onready var player_attack_controler: AttackControler = $"../Player/AttackControler"
@onready var player_health: Health = $"../Player/HealthComponent"
@onready var spawner: Spawner = $Spawner
@onready var background: Background = $"../Background"
@onready var shop_manager: ShopManager = $"../ShopManager"
@onready var label_manager: LabelManager = $LabelManager

enum Enemies {
	METEOR,
	UFO
}

var is_running: bool = true
var score : float = 0
var escaped: int
var wave_count: int = 0
var difficulty: float = 1
var difficulty_wave_gain: float = 0.25
var wave_duration: int = 10
var wave_finished: bool = false

func _ready() -> void:
	await get_tree().process_frame
	spawner.set_spawn_timer(wave_duration)
	background.set_animation_active(true)
	label_manager.configure_default_labels()
	label_manager.show_wave_label()
	update_player_health_label()

func _process(_delta: float):
	pass

func finish_wave() -> void:
	print("finishing wave")
	set_wave_finished(true)
	set_player(false)
	label_manager.show_wave_finished_label()
	add_difficulty(difficulty_wave_gain)
	print("new difficulty: %s" % difficulty)
	# background.set_animation_active(false)
	spawner.kill_all_enemies()
	shop_manager.show_shop()

func start_next_wave() -> void:
	set_wave_finished(false)
	set_player(true)
	# background.set_animation_active(true)
	spawner.set_ready_to_spawn(true)

func update_player_health_label() -> void:
	var health: float
	if player_health:
		health = player_health.get_health()
	else:
		health = 0
	label_manager.update_health_label(health)

func set_player(value: bool) -> void:
	player.set_process(value)
	# player.visible = value
	if value == false:
		player.direction = Vector2.ZERO
	player_attack_controler.set_process(value)

func get_dificulty() -> float:
	return difficulty

func set_difficulty(new_difficulty: float) -> void:
	difficulty = new_difficulty

func add_difficulty(value: float) -> void:
	difficulty += value

func update_score(points: float):
	score += points
	label_manager.update_score_label(score)

func inc_esaped() -> void:
	escaped += 1

func increment_wave_count() -> void:
	wave_count += 1

func get_wave_count() -> int:
	return wave_count

func set_wave_finished(value: bool) -> void:
	wave_finished = value

func get_wave_finished() -> bool:
	return wave_finished

func get_score() -> float:
	return score

func get_running() -> bool:
	return is_running

func get_spawn_timer_time() -> float:
	return spawner.spawn_timer.time_left

func get_shop_timer_time() -> float:
	return shop_manager.shop_timer.time_left

func get_escaped() -> int:
	return escaped

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset") and !is_running:
		reload_scene()

func _on_player_player_damage_taken() -> void:
	update_player_health_label()

func _on_player_player_died() ->  void:
	is_running = false
	label_manager.show_end_game_labels()

func reload_scene() -> void:
	if get_tree():
		get_tree().reload_current_scene()
