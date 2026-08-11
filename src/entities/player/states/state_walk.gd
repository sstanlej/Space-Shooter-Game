class_name State_Walk extends State

@onready var idle : State = $"../Idle"

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func Process(_delta : float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	if player.position.y <= 10 and player.direction.y < 0:
		player.direction.y = 0
	if player.position.y >= 110 and player.direction.y > 0:
		player.direction.y = 0
	if player.position.x <= 12 and player.direction.x < 0:
		player.direction.x = 0
	if player.position.x >= 230 and player.direction.x > 0:
		player.direction.x = 0

	var speed = player.stats_component.get_final_movement_speed() if player.stats_component else 200.0
	player.velocity = player.direction.normalized() * speed
	return null

func Physics(_delta : float) -> State:
	return null

func HandleInput(_event : InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		player.is_attacking = true
	if _event.is_action_released("attack"):
		player.is_attacking = false
	return null
