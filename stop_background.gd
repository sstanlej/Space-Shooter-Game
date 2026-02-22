extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_background"):
		if animation_player.active == false:
			animation_player.active = true
		else:
			animation_player.active = false
		
