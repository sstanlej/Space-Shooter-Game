class_name ShopManager extends Sprite2D

@onready var game_manager: GameManager = $"../GameManager"
@onready var shop_timer: Timer = $ShopTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await get_tree().process_frame

func show_shop() -> void:
	shop_timer.start()
	animation_player.play("show")
	print("showing shop")

func _process(_delta: float) -> void:
	pass

func _on_shop_timer_timeout() -> void:
	print("shop timer finished")
	animation_player.play("hide")
	game_manager.start_next_wave()
