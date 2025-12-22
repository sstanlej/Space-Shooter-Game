class_name Collectable extends CharacterBody2D

@export var duration_time: float = 2
@export var new_cooldown: float = 0.1
@export var speed: float = 30
var old_cooldown: float
var attack_controler: AttackControler

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DurationTime.wait_time = duration_time

func _physics_process(_delta: float) -> void:
	velocity = Vector2.LEFT * speed
	move_and_slide()
	pass

func _on_duration_time_timeout() -> void:
	attack_controler.set_cooldown(old_cooldown)
	queue_free()

func affect_player(player: Player) -> void:
	attack_controler = get_attack_controler(player)
	if(!attack_controler):
		return
			
	old_cooldown = attack_controler.get_cooldown()
	attack_controler.set_cooldown(new_cooldown)
	$DurationTime.start()
	hide()
	set_deferred("monitoring", false)
	
func get_player(area: Area2D) -> Player:
	if area.get_parent() is Player:
		var player: Player = area.get_parent()
		return player
	return null
	
func get_attack_controler(player: Player) -> AttackControler:
	for child in player.get_children():
		if child is AttackControler:
			attack_controler = child
			return attack_controler
	return null

func _on_area_2d_area_entered(area: Area2D) -> void:
	var player = get_player(area)
	if(!player):
		return
	affect_player(player)
