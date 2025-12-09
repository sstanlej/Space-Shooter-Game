class_name State extends Node

# Reference to a player object that is in this state
static var player : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# What happens when the player enters this state
func Enter() -> void:
	pass

# What happens when the player exits this state
func Exit() -> void:
	pass
	
# What happens during _process update in this state
func Process(_delta : float) -> State:
	return null 

# What happens during _physics_process update in this state
func Physics(_delta : float) -> State:
	return null

# What happens with input events in this state
func HandleInput(_delta : float) -> State:
	return null
	
