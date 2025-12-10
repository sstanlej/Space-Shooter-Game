class_name EnemyMovement extends CharacterBody2D
var direction : Vector2 = Vector2.LEFT
@export var move_speed : float = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	velocity = direction * move_speed

func _physics_process(_delta: float) -> void:
	move_and_slide()
