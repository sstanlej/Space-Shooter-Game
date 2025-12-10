class_name AttackControler extends Node

static var player : Player
var is_ready : bool = true
const bullet = preload("res://Bullet/bullet.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = $".."
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.is_attacking and is_ready:
		var bullet_instance = bullet.instantiate()
		add_child(bullet_instance)
		bullet_instance.position = player.position
		is_ready = false
		$CooldownTimer.start()


func _on_cooldown_timer_timeout() -> void:
	is_ready = true
