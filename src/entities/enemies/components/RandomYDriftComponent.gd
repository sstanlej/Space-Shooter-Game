class_name RandomYDriftComponent extends Node

@export var min_interval: float = 1.5
@export var max_interval: float = 3.5
@export var lerp_speed: float = 3.0
@export var screen_margin: float = 25.0

var target_y: float
var movement_comp: EnemyMovementComponent

func _ready() -> void:
	movement_comp = owner.get_node_or_null("EnemyMovementComponent")
	schedule_next_drift()

func on_enemy_setup() -> void:
	if movement_comp:
		target_y = movement_comp.base_y

func schedule_next_drift() -> void:
	var wait_time = randf_range(min_interval, max_interval)
	get_tree().create_timer(wait_time).timeout.connect(pick_new_y)

func pick_new_y() -> void:
	if not is_instance_valid(owner):
		return
	var screen_h = owner.get_viewport_rect().size.y
	target_y = randf_range(screen_margin, screen_h - screen_margin)
	schedule_next_drift()

func _physics_process(delta: float) -> void:
	if movement_comp:
		movement_comp.base_y = lerp(movement_comp.base_y, target_y, lerp_speed * delta)