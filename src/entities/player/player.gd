class_name Player extends CharacterBody2D

var direction : Vector2 = Vector2.ZERO
var is_attacking : bool = false
signal player_died
signal player_damage_taken
@onready var state_machine : PlayerStateMachine = $StateMachine
@onready var attack_controler: AttackControler = $AttackControler
@onready var health_component: HealthComponent = $HealthComponent
@export var movement_speed: float = 5

var menu_pos_x: float = -240
var game_pos_x: float = 30
var tween: Tween

func _ready() -> void:
	state_machine.Initialize(self)
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
	move_and_slide()

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 2)
	return tw

func set_is_attacking(value: bool) -> void:
	is_attacking = value

func get_health_component() -> HealthComponent:
	return health_component

func get_movement_speed() -> float:
	return movement_speed

func set_movement_speed(new_movement_speed: float) -> void:
	movement_speed = new_movement_speed

func add_movement_speed(value: float) -> void:
	movement_speed += value

func get_attack_controler() -> AttackControler:
	return attack_controler

func _on_player_died() -> void:
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken() -> void:
	player_damage_taken.emit()

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
