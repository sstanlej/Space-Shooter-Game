class_name Player extends CharacterBody2D

signal player_died
signal player_damage_taken

@export var game_pos_x: float = 30.0
@export var menu_pos_x: float = -240.0

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var attack_controller: AttackController = $AttackController
@onready var health_component: HealthComponent = $HealthComponent
@onready var stats_component: PlayerStatsComponent = $PlayerStatsComponent

var direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var tween: Tween

func _ready() -> void:
	if state_machine:
		state_machine.Initialize(self)
	if health_component:
		health_component.died.connect(_on_player_died)

	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

func _process(_delta: float) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

func _physics_process(_delta: float) -> void:
	var current_speed = stats_component.get_final_movement_speed() if stats_component else 200.0
	velocity = direction.normalized() * current_speed
	move_and_slide()

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 2.0)
	return tw

func set_is_attacking(value: bool) -> void:
	is_attacking = value

func _on_player_died() -> void:
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken() -> void:
	player_damage_taken.emit()

func get_health_component() -> HealthComponent:
	return health_component

func get_attack_controller() -> AttackController:
	return attack_controller

func get_movement_speed() -> float:
	if stats_component:
		return stats_component.get_final_movement_speed()
	return 200.0
