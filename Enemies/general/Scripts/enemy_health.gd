extends Health

@export var points: float = 10
@export var experience: float = 10
signal died(points: float, experience: float)

func die() -> void:
	died.emit(points, experience)
	get_parent().queue_free()
