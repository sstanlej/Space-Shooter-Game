class_name GameManager extends Node2D

@onready var score_label: RichTextLabel = $ScoreLabel
@onready var health_label: RichTextLabel = $HealthLabel
@onready var player_health: Health = $"../Player/HealthComponent"

var score : float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score = 0

func _process(_delta: float):
	if player_health:
		update_health(player_health.get_health())
	else:
		update_health(0)

func update_score(points: float):
	score += points
	score_label.text = "Score: " + str(roundi(score))

func update_health(health: float):
	health_label.text = "Health: " + str(roundi(health))


func _on_player_player_died() ->  void:
	print(score)
