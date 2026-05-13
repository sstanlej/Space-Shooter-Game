class_name CameraFrame extends Node2D

static var pos_game_x: float = 0
static var pos_menu_x: float = -240

func move_to_game_view() -> Tween:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", pos_game_x, 1.2)
	return tween

func move_to_menu_view() -> void:
	position = Vector2(pos_menu_x, 0)

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("ui_right") and Input.is_key_pressed(KEY_SHIFT):
		position.x += 3
	if Input.is_action_pressed("ui_left") and Input.is_key_pressed(KEY_SHIFT):
		position.x -= 3
	if Input.is_action_pressed("ui_down") and Input.is_key_pressed(KEY_SHIFT):
		position.y += 3
	if Input.is_action_pressed("ui_up") and Input.is_key_pressed(KEY_SHIFT):
		position.y -= 3
