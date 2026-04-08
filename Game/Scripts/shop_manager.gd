class_name ShopManager extends Sprite2D

@onready var game_manager: GameManager = $"../GameManager"
@onready var shop_timer: Timer = $ShopTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var options = [$ShopOptions/AttackSpeedUpgrade, $ShopOptions/AttackDamageUpgrade]
@onready var selected_icon: Sprite2D = $ShopOptions/SelectedIcon

var current_option: PlayerUpgrade
var previous_option: PlayerUpgrade
var next_option: PlayerUpgrade
var active: bool = false
var selected: int = 0

func _ready() -> void:
	await get_tree().process_frame
	previous_option = null
	current_option = options[0]
	next_option = options[1]
	selected_icon.position = current_option.position

func show_shop() -> void:
	shop_timer.start()
	animation_player.play("show")
	active = true
	print("showing shop")

func _process(_delta: float) -> void:
	if not active:
		return
	if Input.is_action_just_pressed("right") and selected < options.size()-1:
		selected += 1
		previous_option = current_option
		current_option = next_option
		next_option = options[selected+1] if selected < options.size()-1 else null
		selected_icon.position = current_option.position
		print(selected)
	if Input.is_action_just_pressed("left") and selected > 0:
		selected -= 1
		next_option = current_option
		current_option = previous_option
		previous_option = options[selected-1] if selected > 0 else null
		selected_icon.position = current_option.position
		print(selected)


func _on_shop_timer_timeout() -> void:
	print("shop timer finished")
	animation_player.play("hide")
	current_option.affect_player()
	active = false
	game_manager.start_next_wave()
