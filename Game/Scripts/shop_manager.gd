class_name ShopManager extends Sprite2D

@onready var game_manager: GameManager = $"../GameManager"
@onready var shop_timer: Timer = $ShopTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var description_label: RichTextLabel = $DescriptionLabel

@onready var options = [$ShopOptions/AttackSpeedUpgrade, $ShopOptions/MovementSpeedUpgrade, $ShopOptions/AttackDamageUpgrade]
@onready var selected_icon: Sprite2D = $ShopOptions/SelectedIcon

var current_option: PlayerUpgrade
var previous_option: PlayerUpgrade
var next_option: PlayerUpgrade
var active: bool = false
var selected: int = 0

var tween: Tween

func _ready() -> void:
	await get_tree().process_frame
	reset_tween()
	previous_option = null
	current_option = options[0]
	next_option = options[1]
	selected_icon.position = current_option.position

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
	# animation_player.play("show")
	move_open()
	active = true
	update_description_label()
	print("Showing shop")

func update_description_label() -> void:
	var description: String = "[center]" + current_option.description
	description_label.text = description

func _on_shop_timer_timeout() -> void:
	print("Hiding shop")
	# animation_player.play("hide")
	move_close()
	current_option.affect_player()
	active = false
	game_manager.start_next_wave()

func move_open() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position:y", 65, 0.8)
	tween.tween_property(self, "global_position:y", 60, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", 65, 0.2).set_ease(Tween.EASE_IN)

func move_close() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position:y", -65, 1)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
