class_name AttackController extends Node

@export var equipped_weapon: WeaponData
@export var projectiles_container: Node2D

@onready var cooldown_timer: Timer = $CooldownTimer
var player: Player
var is_ready: bool = true

func _ready() -> void:
	player = get_parent() as Player
	if not cooldown_timer:
		cooldown_timer = Timer.new()
		cooldown_timer.name = "CooldownTimer"
		add_child(cooldown_timer)
	cooldown_timer.one_shot = true

func _process(_delta: float) -> void:
	if player and player.is_attacking and is_ready and equipped_weapon:
		shoot()

func equip_weapon(new_weapon: WeaponData) -> void:
	equipped_weapon = new_weapon
	is_ready = true

func shoot() -> void:
	if not equipped_weapon or not equipped_weapon.bullet_scene:
		return

	var stats = player.stats_component if player else null
	var base_dmg = equipped_weapon.base_damage
	var final_dmg = stats.get_final_damage(base_dmg) if stats else base_dmg

	var base_atk_spd = equipped_weapon.base_attack_speed
	var final_atk_spd = stats.get_final_attack_speed(base_atk_spd) if stats else base_atk_spd

	var total_bullets = equipped_weapon.projectiles_per_shot
	if stats:
		total_bullets = stats.get_final_projectiles_count(total_bullets)

	spawn_bullets(final_dmg, equipped_weapon.base_bullet_speed, total_bullets, equipped_weapon.spread_angle_degrees)

	if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_laser"):
		GlobalAudio.play_laser()
	is_ready = false

	var cooldown = 1.0 / max(0.1, final_atk_spd)
	cooldown_timer.start(cooldown)

func spawn_bullets(dmg: float, speed: float, count: int, spread_deg: float) -> void:
	var container = get_target_container()
	var spawn_pos = player.global_position if player else Vector2.ZERO
	var tilt_rad = player.get_tilt_angle() if player and player.has_method("get_tilt_angle") else 0.0

	# 1. Pojedynczy pocisk pod kątem przechyłu
	if count <= 1:
		var dir = Vector2.RIGHT.rotated(tilt_rad)
		spawn_single_bullet(container, spawn_pos, dir, dmg, speed)
		return

	# 2. Wiele pocisków / Rozrzut (Spread) z uwzględnieniem przechyłu
	var start_angle = -spread_deg / 2.0
	var step = spread_deg / float(count - 1) if count > 1 else 0.0

	for i in range(count):
		var current_angle = start_angle + (i * step)
		var dir = Vector2.RIGHT.rotated(tilt_rad + deg_to_rad(current_angle))
		spawn_single_bullet(container, spawn_pos, dir, dmg, speed)

func get_target_container() -> Node:
	if projectiles_container and is_instance_valid(projectiles_container):
		return projectiles_container

	var group_container = get_tree().get_first_node_in_group("projectiles_container") as Node2D
	if group_container:
		projectiles_container = group_container
		return projectiles_container

	return get_tree().current_scene

func spawn_single_bullet(container: Node, pos: Vector2, dir: Vector2, dmg: float, speed: float) -> void:
	if not equipped_weapon or not equipped_weapon.bullet_scene:
		return
		
	var bullet = equipped_weapon.bullet_scene.instantiate() as Projectile
	if bullet:
		container.add_child(bullet)
		bullet.global_position = pos
		bullet.setup(dmg, speed, dir)

func _on_cooldown_timer_timeout() -> void:
	is_ready = true