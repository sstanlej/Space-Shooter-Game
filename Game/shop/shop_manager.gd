class_name ShopManager extends Sprite2D

@export var game_manager: GameManager
@export var player: Player
@onready var shop_timer: Timer = $ShopTimer
@onready var description_label: RichTextLabel = $DescriptionLabel
@onready var stats_label: RichTextLabel = $StatsLabel

@onready var options = [$ShopOptions/AttackSpeedUpgrade, $ShopOptions/MovementSpeedUpgrade, $ShopOptions/AttackDamageUpgrade]
@onready var selected_icon: Sprite2D = $ShopOptions/SelectedIcon

var current_option: PlayerUpgrade
var previous_option: PlayerUpgrade
var next_option: PlayerUpgrade
var active: bool = false
var selected: int = 0

@export var closed_y: int = -65
@export var open_y: int = 66

var tween: Tween

func _ready() -> void:
	await get_tree().process_frame
	previous_option = null
	current_option = options[0]
	next_option = options[1]
	selected_icon.position = current_option.position
	update_stats_label()

func _process(_delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("right") and selected < options.size()-1:
		selected += 1
		previous_option = current_option
		current_option = next_option
		next_option = options[selected+1] if selected < options.size()-1 else null
		selected_icon.position = current_option.position
		update_description_label()
	if Input.is_action_just_pressed("left") and selected > 0:
		selected -= 1
		next_option = current_option
		current_option = previous_option
		previous_option = options[selected-1] if selected > 0 else null
		selected_icon.position = current_option.position
		update_description_label()
	if Input.is_action_just_pressed("attack"):
		shop_timer.stop()
		shop_timer.timeout.emit()

func show_shop() -> void:
	shop_timer.start()
	move_open()
	update_stats_label()
	await get_tree().create_timer(0.5).timeout
	active = true
	update_description_label()
	print("Showing shop")

func hide_shop() -> void:
	print("Hiding shop")
	move_close()
	current_option.affect_player(player)
	update_stats_label()
	active = false
	await get_tree().create_timer(0.2).timeout
	game_manager.toggle_pause()
	# game_manager.set_player(true)
	# game_manager.start_next_wave()

func update_description_label() -> void:
	var description: String = "[center]" + current_option.description
	description_label.text = description

func update_stats_label() -> void:
	var player_damage: int = int(player.get_attack_controler().get_damage())
	var player_attack_speed: int = int(player.get_attack_controler().get_attack_speed())
	var player_speed: int = int(player.get_movement_speed())
	game_manager.get_ui_manager().update_stats_label(player_damage, player_speed, player_attack_speed)

func _on_shop_timer_timeout() -> void:
	hide_shop()

func move_open() -> void:
	reset_tween()
	print("Start animacji z Y: ", position.y)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", open_y, 0.8)
	tween.tween_property(self, "position:y", open_y-5, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", open_y, 0.2).set_ease(Tween.EASE_IN)
	print("KONIEC animacji Y: ", position.y)


func move_close() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", closed_y, 1)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	print("Tween stworzony dla: ", name) # Sprawdźmy czy to ten obiekt


func _on_visibility_changed() -> void:
	print("CHANGED")
