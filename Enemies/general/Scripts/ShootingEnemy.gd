class_name ShootingEnemy extends Enemy

@export_group("Shooting Settings")
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 180.0
@export var bullet_damage: float = 1.0
@export var fire_rate: float = 3.0
@export var burst_count: int = 2
@export var burst_delay: float = 0.15

var shoot_timer: Timer

func _ready() -> void:
	setup_shoot_timer()

func setup_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.wait_time = fire_rate
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

func _on_shoot_timer_timeout() -> void:
	if not is_instance_valid(self):
		return
	start_burst()

func start_burst() -> void:
	for i in range(burst_count):
		shoot_single_bullet()
		await get_tree().create_timer(burst_delay).timeout

func shoot_single_bullet() -> void:
	if not is_instance_valid(self) or not bullet_scene:
		return

	GlobalAudio.play_laser()
	var bullet_instance = bullet_scene.instantiate() as Projectile
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position

	bullet_instance.setup(bullet_damage, bullet_speed, Vector2.DOWN)