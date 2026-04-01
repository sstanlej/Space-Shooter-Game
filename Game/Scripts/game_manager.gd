class_name GameManager extends Node2D

@onready var score_label: RichTextLabel = $ScoreLabel
@onready var health_label: RichTextLabel = $HealthLabel
@onready var player_health: Health = $"../Player/HealthComponent"
@onready var game_over_label: RichTextLabel = $GameOverLabel
@onready var final_score_label: RichTextLabel = $FinalScoreLabel
@onready var play_again_label: RichTextLabel = $PlayAgainLabel
@onready var escaped_label: RichTextLabel = $EscapedLabel
@onready var wave_label: RichTextLabel = $WaveLabel
@onready var wave_label_timer: Timer = $WaveLabelTimer
@onready var spawner: Spawner = $Spawner
@onready var background: Background = $"../Background"
@onready var shop_manager: ShopManager = $ShopManager
#@onready var time_left_label: RichTextLabel = $TimeLeftLabel

enum Enemies {
	METEOR,
	UFO
}

var is_running: bool = true
var score : float = 0
var escaped: int
var wave_count: int = 0
var wave_duration: int = 10
var wave_finished: bool = false

func _ready() -> void:
	await get_tree().process_frame
	game_over_label.visible = false
	final_score_label.visible = false
	play_again_label.visible = false
	escaped_label.visible = false
	wave_label.visible = false
	spawner.set_spawn_timer(wave_duration)
	background.set_animation_active(true)
	show_wave_label()

func _process(_delta: float):
	#time_left_label.text = "%.2f" % spawner.spawn_timer.time_left
	if player_health:
		update_health(player_health.get_health())
	else:
		update_health(0)
	if !is_running and Input.is_action_just_pressed("reset"):
		reload_scene()

func show_wave_label() -> void:
	wave_label_timer.start()
	wave_label.text = "[center]Wave " + str(wave_count)
	wave_label.add_theme_font_size_override("normal_font_size", 15)
	wave_label.visible = true

func show_wave_finished_label() -> void:
	wave_label_timer.start()
	wave_label.text = "[center]Wave finished!"
	wave_label.add_theme_font_size_override("normal_font_size", 10)
	wave_label.visible = true

func inc_esaped() -> void:
	escaped += 1

func increment_wave_count() -> void:
	wave_count += 1

func get_wave_count() -> int:
	return wave_count

func set_wave_finished(value: bool) -> void:
	wave_finished = value

func update_score(points: float):
	score += points
	score_label.text = "Score: " + str(roundi(score))

func get_score() -> float:
	return score

func get_running() -> bool:
	return is_running

func update_health(health: float):
	health_label.text = "Health: " + str(roundi(health))

func _on_player_player_died() ->  void:
	is_running = false
	game_over_label.visible = true
	final_score_label.text = "[center]Score: " + str(roundi(score))
	final_score_label.visible = true
	escaped_label.text = "[center]Enemies escaped: " + str(escaped)
	escaped_label.visible = true
	play_again_label.visible = true
	health_label.visible = false
	score_label.visible = false

func finish_wave() -> void:
	print("finishing wave")
	set_wave_finished(true)
	show_wave_finished_label()
	background.set_animation_active(false)
	spawner.kill_all_enemies()
	shop_manager.show_shop()

func start_next_wave() -> void:
	wave_finished = false
	background.set_animation_active(true)
	spawner.set_ready_to_spawn(true)

func reload_scene() -> void:
	if get_tree():
		get_tree().reload_current_scene()


func _on_wave_label_timer_timeout() -> void:
	wave_label.visible = false
