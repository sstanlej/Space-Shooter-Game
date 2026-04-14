class_name Player extends CharacterBody2D

var direction : Vector2 = Vector2.ZERO
var is_attacking : bool = false
signal player_died
signal player_damage_taken
@onready var state_machine : PlayerStateMachine = $StateMachine
@onready var attack_controler: AttackControler = $AttackControler
@export var movement_speed: float = 5

func _ready() -> void:
	state_machine.Initialize(self)

func _process(_delta: float) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

func _physics_process(_delta: float) -> void:
	move_and_slide()

func get_movement_speed() -> float:
	return movement_speed

func set_movement_speed(new_movement_speed: float) -> void:
	movement_speed = new_movement_speed

func add_movement_speed(value: float) -> void:
	movement_speed += value

func get_attack_controler() -> AttackControler:
	return attack_controler

func _on_tree_exiting() -> void:
	emit_signal("player_died")

func _on_health_component_damage_taken() -> void:
	emit_signal("player_damage_taken")
