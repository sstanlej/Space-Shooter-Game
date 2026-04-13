class_name AttackControler extends Node

static var player : Player
var is_ready : bool = true
var damage: float
var boosted: bool = false
var cooldown: float = 0.33
@export var original_damage: float = 1
@export var bullet_speed: float = 200
@export var attack_speed: float = 3
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	player = $".."
	damage = original_damage
	cooldown = 1/attack_speed
	set_cooldown(cooldown)

func _process(_delta: float) -> void:
	if player.is_attacking and is_ready:
		var bullet_instance = Bullet.spawn_bullet(damage, bullet_speed, boosted)
		add_child(bullet_instance)
		bullet_instance.position = player.position
		GlobalAudio.play_laser()
		is_ready = false
		cooldown_timer.start()

func set_damage(new_dmg: float) -> void:
	damage = new_dmg

func add_damage(value: float) -> void:
	damage += value

func get_damage() -> float:
	return damage

func set_attack_speed(new_attack_speed: float) -> void:
	cooldown_timer.wait_time = 1/new_attack_speed

func add_attack_speed(value: float) -> void:
	attack_speed += value
	set_attack_speed(attack_speed)

func get_attack_speed() -> float:
	return attack_speed

func set_cooldown(new_cooldown: float) -> void:
	cooldown_timer.wait_time = new_cooldown

func get_original_damage() -> float:
	return original_damage

func get_original_cooldown() -> float:
	return cooldown

func get_cooldown() -> float:
	return cooldown_timer.wait_time

func _on_cooldown_timer_timeout() -> void:
	is_ready = true
