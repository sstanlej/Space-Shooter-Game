class_name WarningIndicator extends Sprite2D

var lifetime: float = 0.6

func setup(duration: float, target_position: Vector2) -> void:
	lifetime = duration
	global_position = target_position

	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	start_blinking()

func start_blinking() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)