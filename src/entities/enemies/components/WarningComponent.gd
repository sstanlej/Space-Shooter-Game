class_name WarningComponent extends Node

@export var warning_duration: float = 0.6
@export var warning_indicator_scene: PackedScene

var movement_comp: EnemyMovementComponent
var hurtbox: Area2D

func _ready() -> void:
	movement_comp = owner.get_node_or_null("EnemyMovementComponent")
	hurtbox = owner.get_node_or_null("HurtboxComponent")

	# Natychmiastowe zamrożenie w klatce zero
	if movement_comp:
		movement_comp.can_move = false
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

func on_enemy_setup() -> void:
	if not is_instance_valid(owner):
		return

	var screen_w = owner.get_viewport_rect().size.x
	owner.global_position.x = screen_w + 30.0

	spawn_indicator(screen_w)
	get_tree().create_timer(warning_duration).timeout.connect(_on_warning_finished)

func spawn_indicator(screen_x: float) -> void:
	if warning_indicator_scene and owner.get_parent():
		var indicator = warning_indicator_scene.instantiate()
		owner.get_parent().add_child(indicator)
		var indicator_pos = Vector2(screen_x - 15.0, owner.global_position.y)
		indicator.global_position = indicator_pos
		if indicator.has_method("setup"):
			indicator.setup(warning_duration, indicator_pos)

func _on_warning_finished() -> void:
	if not is_instance_valid(owner):
		return
	if movement_comp:
		movement_comp.can_move = true
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)