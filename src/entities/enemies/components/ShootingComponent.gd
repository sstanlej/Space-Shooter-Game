class_name ShootingComponent extends Node

@export_group("Shooting Settings")
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 180.0
@export var bullet_damage: float = 1.0
@export var fire_rate: float = 3.0
@export var burst_count: int = 2
@export var burst_delay: float = 0.15
@export var initial_delay: float = 0.0

@export_group("Directions")
@export var shot_directions: Array[Vector2] = [
	Vector2.UP,
	Vector2.DOWN
]

var shoot_timer: Timer

func _ready() -> void:
	setup_shoot_timer()

func setup_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.name = "ShootTimer"
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

func on_enemy_setup() -> void:
	if not is_instance_valid(owner):
		return

	if initial_delay > 0.0:
		get_tree().create_timer(initial_delay).timeout.connect(func():
			if is_instance_valid(owner):
				start_burst()
				if shoot_timer:
					shoot_timer.start(fire_rate)
		)
	else:
		start_burst()
		if shoot_timer:
			shoot_timer.start(fire_rate)

func _on_shoot_timer_timeout() -> void:
	if not is_instance_valid(owner):
		return
	start_burst()

func start_burst() -> void:
	for i in range(burst_count):
		if not is_instance_valid(owner):
			return
		shoot_salvo()
		if i < burst_count - 1:
			await get_tree().create_timer(burst_delay).timeout

func shoot_salvo() -> void:
	if not is_instance_valid(owner) or not bullet_scene or shot_directions.is_empty():
		return

	if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_laser"):
		GlobalAudio.play_laser()

	var container = get_target_container()

	for dir in shot_directions:
		var normalized_dir = dir.normalized()
		if normalized_dir == Vector2.ZERO:
			continue

		var bullet = bullet_scene.instantiate() as Projectile
		if bullet:
			container.add_child(bullet)
			bullet.global_position = owner.global_position
			bullet.setup(bullet_damage, bullet_speed, normalized_dir)
			bullet.rotation = normalized_dir.angle()

func get_target_container() -> Node:
	var group_container = get_tree().get_first_node_in_group("projectiles_container") as Node2D
	if group_container and is_instance_valid(group_container):
		return group_container
	if owner and is_instance_valid(owner) and owner.get_parent():
		return owner.get_parent()
	return get_tree().current_scene
