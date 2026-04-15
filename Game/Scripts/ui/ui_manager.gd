class_name UIManager extends Sprite2D

@onready var heart_start_position: Transform2D = $HeartStartPosition.transform
@onready var hearts: Array = [$Heart1, $Heart2, $Heart3, $Heart4]
@onready var player: Player = $"../../Player"
@onready var game_manager: GameManager = $"../../GameManager"
@onready var score_label: RichTextLabel = $ScoreLabel

var player_health: int
var player_score: float
var max_health: int
var missing_hearts: int = hearts.size() - player_health
var heart_visible: Array = []

func _ready() -> void:
	update_score_label(0)
	max_health = hearts.size()
	for i in hearts.size():
		hearts[i].hide()
		# heart_visible.append(0)

func _process(_delta: float) -> void:
	if player:
		player_health = roundi(player.get_health_component().get_health())
		missing_hearts = max_health - player_health
		heart_visible = []
		for i in player_health:
			heart_visible.append(1)
		for i in missing_hearts:
			heart_visible.append(0)
		for i in heart_visible.size():
			hearts[i].visible = heart_visible[i]
	else:
		for i in heart_visible.size():
			hearts[i].visible = false
			pass

func update_score_label(score: int) -> void:
	score_label.text = "[center]" + str(score)
