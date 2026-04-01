extends Health

@export var points: float = 10
@onready var game_manager : GameManager = $"../../GameManager"

func die() -> void:
	game_manager.update_score(points)
	get_parent().queue_free()
