class_name AttackController extends Node

@export_group("Weapon Settings")
@export var equipped_weapon: WeaponData
@export var projectiles_container: Node2D
@export var default_parallel_spacing: float = 6.0

@export_group("Ghost Bullet Support")
@export var ghost_bullet_scene: PackedScene

@onready var cooldown_timer: Timer = get_node_or_null("CooldownTimer")

var player: Player
var is_ready: bool = true
var is_ghost_mode: bool = false
var ghost_bullet_texture: Texture2D

func _ready() -> void:
	player = get_parent() as Player
	if not cooldown_timer:
		cooldown_timer = Timer.new()
		cooldown_timer.name = "CooldownTimer"
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
		add_child(cooldown_timer)
	elif not cooldown_timer.timeout.is_connected(_on_cooldown_timer_timeout):
		cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

	await get_tree().process_frame
	if player and player.get_deck_component():
		var deck = player.get_deck_component()
		if deck.equipped_weapon:
			equip_weapon(deck.equipped_weapon)

func _process(_delta: float) -> void:
	if player and player.is_attacking and is_ready and equipped_weapon:
		shoot()

func equip_weapon(new_weapon: WeaponData) -> void:
	equipped_weapon = new_weapon
	is_ready = true

func set_ghost_mode(enabled: bool, custom_texture: Texture2D = null) -> void:
	is_ghost_mode = enabled
	ghost_bullet_texture = custom_texture

func shoot() -> void:
	if not equipped_weapon or not equipped_weapon.bullet_scene:
		return

	var deck = player.get_deck_component() if player else null
	var base_dmg = equipped_weapon.base_damage
	var final_dmg = deck.get_final_damage(base_dmg) if deck else base_dmg

	var base_atk_spd = equipped_weapon.base_attack_speed
	var final_atk_spd = deck.get_final_attack_speed(base_atk_spd) if deck else base_atk_spd

	var total_bullets = equipped_weapon.projectiles_per_shot
	if deck:
		total_bullets = deck.get_final_projectiles_count(total_bullets)

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

	if count <= 1:
		var dir = Vector2.RIGHT.rotated(tilt_rad)
		spawn_single_bullet(container, spawn_pos, dir, dmg, speed)
		return

	var forward_dir = Vector2.RIGHT.rotated(tilt_rad)
	var perp_dir = Vector2.DOWN.rotated(tilt_rad)

	var spacing = default_parallel_spacing
	if equipped_weapon and "parallel_bullet_spacing" in equipped_weapon and equipped_weapon.parallel_bullet_spacing > 0.0:
		spacing = equipped_weapon.parallel_bullet_spacing

	var mid_index = (count - 1) / 2.0

	for i in range(count):
		var offset = (i - mid_index) * spacing
		var bullet_pos = spawn_pos + (perp_dir * offset)

		var bullet_dir = forward_dir
		if spread_deg > 0.0:
			var start_angle = -spread_deg / 2.0
			var step = spread_deg / float(count - 1)
			var current_angle = start_angle + (i * step)
			bullet_dir = Vector2.RIGHT.rotated(tilt_rad + deg_to_rad(current_angle))

		spawn_single_bullet(container, bullet_pos, bullet_dir, dmg, speed)

func spawn_single_bullet(container: Node, pos: Vector2, dir: Vector2, dmg: float, speed: float) -> void:
	var target_scene = equipped_weapon.bullet_scene
	if is_ghost_mode and ghost_bullet_scene:
		target_scene = ghost_bullet_scene

	if not target_scene:
		return

	var bullet = target_scene.instantiate() as Projectile
	if not bullet:
		return

	container.add_child(bullet)
	bullet.global_position = pos
	bullet.setup(dmg, speed, dir)
	bullet.rotation = dir.angle()

	if is_ghost_mode:
		configure_as_ghost_bullet(bullet)

func configure_as_ghost_bullet(bullet: Projectile) -> void:
	bullet.collision_layer = 0
	bullet.collision_mask = 0

	for child in bullet.get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

	var bullet_sprite = bullet.get_node_or_null("Sprite2D") as Sprite2D
	if bullet_sprite:
		if ghost_bullet_texture:
			bullet_sprite.texture = ghost_bullet_texture
			bullet_sprite.modulate = Color.WHITE
		else:
			bullet_sprite.modulate = Color(0.7, 0.9, 1.0, 0.4)

func get_target_container() -> Node:
	if projectiles_container and is_instance_valid(projectiles_container):
		return projectiles_container

	var group_container = get_tree().get_first_node_in_group("projectiles_container") as Node2D
	if group_container and is_instance_valid(group_container):
		projectiles_container = group_container
		return projectiles_container

	return get_tree().current_scene

func _on_cooldown_timer_timeout() -> void:
	is_ready = true