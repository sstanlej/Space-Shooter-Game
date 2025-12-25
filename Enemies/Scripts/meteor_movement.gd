class_name EnemyMovement extends CharacterBody2D
var direction : Vector2 = Vector2.LEFT
var rng = RandomNumberGenerator.new()
@export var move_speed : float = 30
@export var dmg : float = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# move_speed = randf_range(move_speed/2, move_speed)
	pass # Replace with function body.

func set_move_speed(new_speed: float) -> void:
	move_speed = new_speed

func get_move_speed() -> float:
	return move_speed

func _physics_process(_delta: float) -> void:
	if self.position.x < -5:
		inc_escaped()
		queue_free()
	velocity = direction * move_speed
	move_and_slide()
	rotate(0.05)
	pass

func inc_escaped() -> void:
	var scene = get_parent()
	for child in scene.get_children():
		if child is GameManager:
			child.inc_esaped()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("damage"):
		area.damage(dmg)
		GlobalAudio.play_crash()
		queue_free()
