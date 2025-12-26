class_name AttackControler extends Node

static var player : Player
var is_ready : bool = true
var cooldown: float = 0.33
var original_damage: float = 1
var damage: float
var bullet_speed: float = 200

func _ready() -> void:
	player = $".."
	set_cooldown(cooldown)
	damage = original_damage

func set_damage(new_dmg: float) -> void:
	damage = new_dmg

func get_damage() -> float:
	return damage

func get_original_damage() -> float:
	return original_damage

func get_original_cooldown() -> float:
	return cooldown

func get_cooldown() -> float:
	return $CooldownTimer.wait_time

func set_cooldown(new_cooldown: float) -> void:
	$CooldownTimer.wait_time = new_cooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.is_attacking and is_ready:
		var bullet_instance = Bullet.spawn_bullet(damage, bullet_speed)
		add_child(bullet_instance)
		bullet_instance.position = player.position
		GlobalAudio.play_laser()
		is_ready = false
		$CooldownTimer.start()


func _on_cooldown_timer_timeout() -> void:
	is_ready = true
