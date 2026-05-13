class_name UIManager extends TextureRect

@onready var heart_start_position = $HeartStartPosition
@onready var player: Player = $"../../../Player"
@onready var game_manager: GameManager = $"../../../GameManager"
@onready var score_label: RichTextLabel = $ScoreLabel
@onready var damage_label: RichTextLabel = $DamageLabel
@onready var movement_speed_label: RichTextLabel = $MoveSpeedLabel
@onready var attack_speed_label: RichTextLabel = $AttackSpeedLabel
@export var experience_bar: TextureProgressBar
@export var health_full_sprite: Texture
@export var health_empty_sprite: Texture

@onready var start_game_label: RichTextLabel = $"../LabelManager/StartGameLabel"

var hearts: Array
var player_health: int
var player_score: float
var max_health: int
var missing_hearts: int
var heart_visible: Array = []
var health_sprite_offset: int = 12

var tween: Tween

func _ready() -> void:
	start_game_label.visible = true
	update_score_label(0)
	if player:
		max_health = roundi(player.get_health_component().get_health())
		player_health = max_health
	var offset: int = 0
	experience_bar.value = 0
	Heart.set_textures(health_full_sprite, health_empty_sprite)
	for i in range(player_health):
		var heart_instance = Heart.spawn_heart()
		heart_start_position.add_child(heart_instance)
		heart_instance.position.x += offset
		hearts.append(heart_instance)
		heart_instance.set_on(false)
		offset += health_sprite_offset

func _process(_delta: float) -> void:
	if player:
		player_health = roundi(player.get_health_component().get_health())
		update_health_bar(player_health)
	else:
		for i in heart_visible.size():
			hearts[i].set_on(false)
			pass

func update_health_bar(new_health: int) -> void:
	player_health = new_health
	missing_hearts = max_health - player_health
	heart_visible = []
	for i in player_health:
		heart_visible.append(1)
	for i in missing_hearts:
		heart_visible.append(0)
	for i in heart_visible.size():
		hearts[i].set_on(heart_visible[i])
		# hearts[i].visible = heart_visible[i]

func hide_start_game_label() -> void:
	start_game_label.visible = false

func update_experience_bar(new_value: int) -> void:
	experience_bar.value = new_value

func extend_experience_bar(new_value: int) -> void:
	experience_bar.max_value = new_value

func update_distance_label(distance: float):
	score_label.text = "[center]" + str("%.0f" % distance) + "     km"

func update_score_label(score: int) -> void:
	score_label.text = "[center]" + str(score)

func update_stats_label(damage: int, movement_speed: int, attack_speed: int) -> void:
	damage_label.text = str(damage)
	movement_speed_label.text = str(movement_speed)
	attack_speed_label.text = str(attack_speed)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
