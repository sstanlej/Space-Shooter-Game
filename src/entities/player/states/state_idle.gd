class_name State_Idle extends State

@onready var walk: State = $"../Walk"

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func Process(_delta: float) -> State:
	# Przejście do Walk następuje TYLKO, gdy gracz wciśnie klawisz
	if player.direction != Vector2.ZERO:
		return walk
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		player.is_attacking = true
	if _event.is_action_released("attack"):
		player.is_attacking = false
	return null