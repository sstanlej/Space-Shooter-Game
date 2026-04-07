class_name ShopManager extends Node2D

@onready var game_manager: GameManager = $".."
@onready var shop_timer: Timer = $ShopTimer

func _ready() -> void:
	await get_tree().process_frame

func show_shop() -> void:
	shop_timer.start()
	print("showing shop")

func _process(_delta: float) -> void:
	pass

func _on_shop_timer_timeout() -> void:
	print("shop timer finished")
	game_manager.start_next_wave()
