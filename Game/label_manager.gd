class_name LabelManager extends Node2D

@onready var game_manager: GameManager = $".."
@onready var time_left_label: RichTextLabel = $TimeLeftLabel
@onready var wave_label: RichTextLabel = $WaveLabel
@onready var wave_label_timer: Timer = $WaveLabelTimer

func _ready() -> void:
	await get_tree().process_frame
	configure_default_labels()

func _process(_delta: float) -> void:
	update_time_left_label()

func configure_default_labels() -> void:
	wave_label.visible = false

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



func _on_wave_label_timer_timeout() -> void:
	wave_label.visible = false
