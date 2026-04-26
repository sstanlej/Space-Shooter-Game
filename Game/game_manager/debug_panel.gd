class_name DebugPanel extends TextureRect

var tween: Tween
var pos_hidden = [0, 135]
var pos_open = [0, 0]
var is_open: bool = false

func _ready() -> void:
	pass

func move_open() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", pos_open[1], 0.8)
	tween.tween_property(self, "position:y", pos_open[1]-10, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", pos_open[1], 0.2).set_ease(Tween.EASE_IN)
	is_open = true

func move_close() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", pos_hidden[1], 1)
	is_open = false

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
