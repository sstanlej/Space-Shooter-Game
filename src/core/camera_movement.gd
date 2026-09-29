class_name CameraFrame extends Node2D

static var pos_game_x: float = 0.0
static var pos_menu_x: float = -240.0

@export_group("Transitions")
@export var transition_duration: float = 1.2

var _shake_power: float = 0.0
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _base_pos_x: float = pos_menu_x
var _is_tweening: bool = false

func _ready() -> void:
	move_to_menu_view()

func move_to_menu_view() -> void:
	_is_tweening = false
	_base_pos_x = pos_menu_x
	position = Vector2(_base_pos_x, 0.0)

func move_to_game_view() -> Tween:
	_is_tweening = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_base_pos_x", pos_game_x, transition_duration)
	tween.finished.connect(func(): _is_tweening = false)
	return tween

func shake(intensity: float, duration: float) -> void:
	_shake_power = intensity
	_shake_duration = duration
	_shake_timer = duration

func _process(delta: float) -> void:
	var shake_offset = Vector2.ZERO

	if _shake_timer > 0.0:
		_shake_timer -= delta
		var damping: float = _shake_timer / _shake_duration
		var current_intensity: float = _shake_power * damping

		shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)

	position.x = _base_pos_x + shake_offset.x
	position.y = shake_offset.y