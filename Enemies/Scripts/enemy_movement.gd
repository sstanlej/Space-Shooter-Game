class_name EnemyMovement extends CharacterBody2D
var direction : Vector2 = Vector2.LEFT
var rng = RandomNumberGenerator.new()
@export var move_speed : float = 30
@export var attack : float = 1
static var my_scene: PackedScene = preload("res://Enemies/meteor.tscn")

static func spawn_enemy(dmg: float, speed: float, health: float) -> EnemyMovement:
	var new_enemy: EnemyMovement = my_scene.instantiate()
	new_enemy.set_attack(dmg)
	new_enemy.set_move_speed(speed)
	new_enemy.set_health(health)
	return new_enemy

func set_move_speed(new_speed: float) -> void:
	move_speed = new_speed

func get_move_speed() -> float:
	return move_speed

func set_attack(new_attack: float):
	attack = new_attack
	
func get_attack() -> float:
	return attack

func set_health(new_health: float):
	$HealthComponent.set_health(new_health)

func _physics_process(_delta: float) -> void:
	if self.position.x < -5:
		inc_escaped()
		queue_free()
	do_movement()

func do_movement() -> void:
	velocity = direction * move_speed
	move_and_slide()
	rotate(0.05)

func inc_escaped() -> void:
	var scene = get_parent()
	for child in scene.get_children():
		if child is GameManager:
			child.inc_esaped()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if !area.has_method("damage"):
		return
	if area.get_parent() is EnemyMovement:
		return
	area.damage(attack)
	GlobalAudio.play_crash()
	queue_free()
