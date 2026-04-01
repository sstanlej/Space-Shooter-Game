class_name LabelManager extends Node2D

@onready var game_manager: GameManager = $".."
@onready var time_left_label: RichTextLabel = $TimeLeftLabel

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	update_time_left_label()

func configure_default_labels() -> void:
	pass

func update_time_left_label() -> void:
	var time_left = game_manager.get_spawn_timer_time()
	time_left_label.text = "%.2f" % time_left