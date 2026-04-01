class_name LabelManager extends Node2D

@onready var game_manager: GameManager = $".."
@onready var score_label: RichTextLabel = $ScoreLabel
@onready var health_label: RichTextLabel = $HealthLabel
@onready var time_left_label: RichTextLabel = $TimeLeftLabel
@onready var escaped_label: RichTextLabel = $EscapedLabel
@onready var game_over_label: RichTextLabel = $GameOverLabel
@onready var final_score_label: RichTextLabel = $FinalScoreLabel
@onready var play_again_label: RichTextLabel = $PlayAgainLabel
@onready var wave_label: RichTextLabel = $WaveLabel
@onready var wave_label_timer: Timer = $WaveLabelTimer

func _ready() -> void:
	await get_tree().process_frame
	configure_default_labels()

func _process(_delta: float) -> void:
	update_time_left_label()

func configure_default_labels() -> void:
	wave_label.visible = false
	escaped_label.visible = false
	game_over_label.visible = false
	final_score_label.visible = false
	play_again_label.visible = false

func update_time_left_label() -> void:
	var time_left: float = game_manager.get_spawn_timer_time()
	time_left_label.text = "%.2f" % time_left

func show_wave_label() -> void:
	var wave_count: int = game_manager.get_wave_count()
	wave_label_timer.start()
	wave_label.text = "[center]Wave " + str(wave_count)
	wave_label.add_theme_font_size_override("normal_font_size", 15)
	wave_label.visible = true

func show_wave_finished_label() -> void:
	wave_label_timer.start()
	wave_label.text = "[center]Wave finished!"
	wave_label.add_theme_font_size_override("normal_font_size", 10)
	wave_label.visible = true

func show_end_game_labels() -> void:
	var escaped: int = game_manager.get_escaped()
	escaped_label.text = "[center]Enemies escaped: " + str(escaped)
	escaped_label.visible = true

	var score: float = game_manager.get_score()
	game_over_label.visible = true
	final_score_label.text = "[center]Score: " + str(roundi(score))
	final_score_label.visible = true

	play_again_label.visible = true
	health_label.visible = false
	score_label.visible = false

func update_score_label(score: float) -> void:
	score_label.text = "Score: " + str(roundi(score))

func update_health_label(health: float) -> void:
	health_label.text = "Health: " + str(roundi(health))


func _on_wave_label_timer_timeout() -> void:
	wave_label.visible = false
