class_name GameManager extends Node2D

@onready var score_label: RichTextLabel = $ScoreLabel

var score : float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score = 0

func update_score(points: float):
	score += points
	score_label.text = "Score: " + str(roundi(score))
