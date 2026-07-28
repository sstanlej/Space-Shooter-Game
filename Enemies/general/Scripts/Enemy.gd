class_name Enemy extends CharacterBody2D

var data: EnemyData

signal enemy_died(points: float, xp: float)

var direction : Vector2 = Vector2.LEFT
var move_speed : float = 30
var attack : float = 1
var score_reward : int = 10
var xp_reward : int = 10
var weight : int = 1

@onready var health_component: HealthComponent = $HealthComponent

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	move_speed = data.enemy_speed
	attack = data.enemy_damage
	if health_component:
		health_component.set_health(data.enemy_max_health)
		if not health_component.died.is_connected(_on_health_component_died):
			health_component.died.connect(_on_health_component_died)

func _physics_process(_delta: float) -> void:
	if position.x < -5:
		# inc_escaped() # Zamiast tego wyslij sygnal do GameManager
		queue_free()
	do_movement(_delta)

func do_movement(_delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()

func _on_health_component_died() -> void:
	enemy_died.emit(data.enemy_score_reward, data.enemy_xp_reward)
	print("Enemy died!")
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent() is Enemy:
		return

	var target = area # Area2D with "hitbox.gd" script

	if target.has_method("damage"):
		target.damage(attack)
		GlobalAudio.play_crash()
		queue_free()
