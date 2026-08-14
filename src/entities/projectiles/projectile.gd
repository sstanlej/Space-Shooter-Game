class_name Projectile extends Area2D

@export var speed: float = 300.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2.RIGHT
var screen_width: float = 0.0

func _ready() -> void:
	screen_width = get_viewport_rect().size.x

func setup(proj_damage: float, proj_speed: float, proj_direction: Vector2) -> void:
	damage = proj_damage
	speed = proj_speed
	direction = proj_direction.normalized()
	# Obrót pocisku w stronę, w którą leci:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if global_position.x > screen_width + 30.0 or global_position.x < -30.0 or global_position.y < -30.0 or global_position.y > get_viewport_rect().size.y + 30.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("damage"):
		area.damage(damage)
		on_hit()

func on_hit() -> void:
	if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_crash"):
		GlobalAudio.play_crash()
	queue_free()