class_name Player extends CharacterBody2D

var direction : Vector2 = Vector2.ZERO
var is_attacking : bool = false
signal player_died
@onready var state_machine : PlayerStateMachine = $StateMachine

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.Initialize(self)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()
	
	pass


func _on_tree_exiting() -> void:
	emit_signal("player_died")
