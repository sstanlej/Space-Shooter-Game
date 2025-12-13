class_name State_Walk extends State

@export var move_speed : float = 100.0
@onready var idle : State = $"../Idle"

# What happens when the player enters this state
func Enter() -> void:
	# print("entered walk state")
	pass

# What happens when the player exits this state
func Exit() -> void:
	pass
	
# What happens during _process update in this state
func Process(_delta : float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	player.velocity = player.direction * move_speed
	return null 

# What happens during _physics_process update in this state
func Physics(_delta : float) -> State:
	return null

# What happens with input events in this state
func HandleInput(_event : InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		player.is_attacking = true
	if _event.is_action_released("attack"):
		player.is_attacking = false
	return null
	
