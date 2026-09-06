class_name RandomYDriftComponent extends Node

@export var min_interval: float = 1.5
@export var max_interval: float = 3.5
@export var lerp_speed: float = 2.0
@export var screen_margin: float = 25.0

var target_y: float = 0.0
var has_target: bool = false
var body: CharacterBody2D

func _ready() -> void:
	body = owner as CharacterBody2D
	if body:
		target_y = body.global_position.y
		has_target = true
	schedule_next_drift()

func on_enemy_setup() -> void:
	if not body:
		body = owner as CharacterBody2D
	if body:
		target_y = body.global_position.y
		has_target = true

func schedule_next_drift() -> void:
	var wait_time = randf_range(min_interval, max_interval)
	get_tree().create_timer(wait_time).timeout.connect(pick_new_y)

func pick_new_y() -> void:
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		return
	var screen_h = owner.get_viewport_rect().size.y
	target_y = randf_range(screen_margin, screen_h - screen_margin)
	has_target = true
	schedule_next_drift()

func _physics_process(delta: float) -> void:
	if not body or not has_target:
		return
	
	body.global_position.y = lerp(body.global_position.y, target_y, lerp_speed * delta)
