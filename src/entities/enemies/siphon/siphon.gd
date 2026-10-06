class_name SiphonEnemy extends Enemy

enum State { PATROL, CHARGING, RECOVERING }

@export_group("Patrol")
@export var patrol_y: float = 16.0
@export var patrol_speed: float = 35.0
@export var edge_margin: float = 14.0

@export_group("Charge")
@export var charge_speed: float = 220.0
@export var recover_speed: float = 90.0
@export var align_threshold: float = 8.0
@export var charge_cooldown: float = 1.4
@export var min_player_depth: float = 18.0

var state: State = State.PATROL
var patrol_direction: float = -1.0
var cooldown_left: float = 0.4
var player_ref: Node2D

@onready var sprite: CanvasItem = get_node_or_null("Sprite2D")
@onready var hurtbox: HurtboxComponent = get_node_or_null("HurtboxComponent")


func _ready() -> void:
	super._ready()
	_snap_to_patrol_lane()
	if hurtbox:
		hurtbox.destroy_on_contact = false
		if not hurtbox.area_entered.is_connected(_on_siphon_area_entered):
			hurtbox.area_entered.connect(_on_siphon_area_entered)


func setup(enemy_data: EnemyData) -> void:
	super.setup(enemy_data)
	_snap_to_patrol_lane()
	has_entered_screen = true
	state = State.PATROL
	player_ref = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if is_escaping:
		return

	cooldown_left = maxf(0.0, cooldown_left - delta)
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node2D

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.CHARGING:
			_process_charge(delta)
		State.RECOVERING:
			_process_recover(delta)


func _process_patrol(delta: float) -> void:
	var vp = get_viewport_rect().size
	global_position.y = patrol_y
	global_position.x += patrol_direction * patrol_speed * delta

	if global_position.x <= edge_margin:
		global_position.x = edge_margin
		patrol_direction = 1.0
	elif global_position.x >= vp.x - edge_margin:
		global_position.x = vp.x - edge_margin
		patrol_direction = -1.0

	_set_sprite_charging(false)

	if cooldown_left <= 0.0 and _is_aligned_over_player():
		state = State.CHARGING
		_set_sprite_charging(true)


func _process_charge(delta: float) -> void:
	global_position.y += charge_speed * delta
	var vp = get_viewport_rect().size
	if global_position.y > vp.y + 8.0:
		_begin_recover()


func _process_recover(delta: float) -> void:
	global_position.y -= recover_speed * delta
	if global_position.y <= patrol_y:
		global_position.y = patrol_y
		state = State.PATROL
		cooldown_left = charge_cooldown
		_set_sprite_charging(false)


func _begin_recover() -> void:
	if state == State.RECOVERING:
		return
	state = State.RECOVERING
	_set_sprite_charging(false)


func _is_aligned_over_player() -> bool:
	if not is_instance_valid(player_ref):
		return false
	if player_ref.global_position.y < global_position.y + min_player_depth:
		return false
	return absf(global_position.x - player_ref.global_position.x) <= align_threshold


func _snap_to_patrol_lane() -> void:
	# var vp = get_viewport_rect().size
	global_position.y = patrol_y
	# global_position.x = clampf(global_position.x, edge_margin, vp.x - edge_margin)


func _set_sprite_charging(charging: bool) -> void:
	if not sprite:
		return
	sprite.rotation_degrees = 90.0 if charging else 0.0


func _on_siphon_area_entered(area: Area2D) -> void:
	if state != State.CHARGING:
		return
	if area.owner is Player:
		_begin_recover()
