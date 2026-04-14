extends Node2D

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("ui_right") and Input.is_key_pressed(KEY_SHIFT):
		position.x += 3
	if Input.is_action_pressed("ui_left") and Input.is_key_pressed(KEY_SHIFT):
		position.x -= 3
	if Input.is_action_pressed("ui_down") and Input.is_key_pressed(KEY_SHIFT):
		position.y += 3
	if Input.is_action_pressed("ui_up") and Input.is_key_pressed(KEY_SHIFT):
		position.y -= 3
