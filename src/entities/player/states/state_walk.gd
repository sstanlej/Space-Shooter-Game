class_name State_Walk extends State

@onready var idle: State = $"../Idle"

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func Process(_delta: float) -> State:
	# Przejście do Idle następuje DOPIERO wtedy, gdy gracz nie trzyma klawiszy I statek prawie całkowicie wyhamował
	if player.direction == Vector2.ZERO and player.velocity.length() < 5.0:
		return idle
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		player.is_attacking = true
	if _event.is_action_released("attack"):
		player.is_attacking = false
	return null