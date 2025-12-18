class_name EnemyMovement extends CharacterBody2D
var direction : Vector2 = Vector2.LEFT
var rng = RandomNumberGenerator.new()
@export var move_speed : float = 30
@export var dmg : float = 1
@onready var crash_sound : AudioStreamPlayer2D = $CrashSound
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# move_speed = randf_range(move_speed/2, move_speed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()
	rotate(0.05)
	pass

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.has_method("damage"):
		area.damage(dmg)
		GlobalAudio.play_crash()
		queue_free()
