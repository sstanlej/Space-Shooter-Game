class_name Bullet extends Area2D

@export var move_speed : float = 200
@export var attack_damage : float = 1
var direction = Vector2.RIGHT

static func spawn_bullet(dmg: float, speed: float) -> Bullet:
	var my_scene: PackedScene = load("res://Bullet/bullet.tscn")
	var new_bullet: Bullet = my_scene.instantiate()
	new_bullet.set_damage(dmg)
	new_bullet.set_speed(speed)
	return new_bullet

func get_damage() -> float:
	return attack_damage
	
func set_damage(new_damage: float):
	attack_damage = new_damage

func get_speed() -> float:
	return move_speed

func set_speed(new_speed: float):
	move_speed = new_speed

func _physics_process(delta: float) -> void:
	position += move_speed * direction * delta
	if position.x > 250:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.find_parent("Player"):
		return
	
	if area.has_method("damage"):
		area.damage(attack_damage)
		queue_free()
