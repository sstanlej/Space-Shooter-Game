class_name Player extends CharacterBody2D

signal player_died
signal player_damage_taken

@export_group("Spawn & Intro Settings")
@export var game_pos_x: float = 30.0
@export var menu_pos_x: float = -120.0

@export_group("Spectator Mode Settings")
@export var spectator_texture: Texture2D
@export var ghost_bullet_texture: Texture2D

@export_group("Component References")
@onready var movement_component: PlayerMovementComponent = get_node_or_null("PlayerMovementComponent")
@onready var visuals_component: PlayerVisualsComponent = get_node_or_null("PlayerVisualsComponent")
@onready var attack_controller: AttackController = get_node_or_null("AttackController")
@onready var health_component: PlayerHealthComponent = get_node_or_null("HealthComponent")
@onready var stats_component: PlayerStatsComponent = get_node_or_null("PlayerStatsComponent")
@onready var deck_component: PlayerDeckComponent = get_node_or_null("PlayerDeckComponent")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var is_attacking: bool = false
var is_in_game: bool = false
var is_spectator: bool = false

var original_texture: Texture2D
var original_collision_layer: int = 0
var original_collision_mask: int = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	position = Vector2(menu_pos_x, 60.0)
	is_in_game = false

	if sprite:
		original_texture = sprite.texture
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

	if health_component:
		health_component.died.connect(_on_player_died)

		if deck_component:
			health_component.shield_hit.connect(deck_component.sync_shield_from_health)

	for child in get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = true
			if child.has_method("restart"):
				child.restart()

func _physics_process(delta: float) -> void:
	if not is_in_game or Input.is_key_pressed(KEY_SHIFT):
		is_attacking = false
	else:
		is_attacking = Input.is_action_pressed("attack")

	if movement_component:
		movement_component.process_movement(delta)

# --- PRZEJŚCIA KAMERY / EKRANU ---

func move_to_game_view() -> Tween:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", game_pos_x, 1.2)
	tw.tween_callback(func(): is_in_game = true)
	return tw

func move_to_menu_view() -> void:
	is_in_game = false
	velocity = Vector2.ZERO
	position = Vector2(menu_pos_x, 60.0)

# --- TRYB SPECTATORA ---

func toggle_spectator_mode() -> bool:
	set_spectator_mode(!is_spectator)
	return is_spectator

func set_spectator_mode(enabled: bool) -> void:
	is_spectator = enabled
	velocity = Vector2.ZERO

	collision_layer = 0 if is_spectator else original_collision_layer
	collision_mask = 0 if is_spectator else original_collision_mask
	set_hurtboxes_enabled(!is_spectator)

	if health_component:
		health_component.is_invincible = is_spectator

	if sprite:
		if is_spectator:
			if spectator_texture:
				sprite.texture = spectator_texture
				sprite.modulate = Color.WHITE
			else:
				sprite.modulate = Color(1.0, 1.0, 1.0, 0.4)
		else:
			sprite.texture = original_texture
			sprite.modulate = Color.WHITE

	if attack_controller:
		attack_controller.set_ghost_mode(is_spectator, ghost_bullet_texture)

func set_hurtboxes_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", enabled)
			child.set_deferred("monitorable", enabled)

# --- SYGNAŁY I GETTERY ---

func _on_player_died() -> void:
	if is_spectator:
		return
	player_died.emit()
	queue_free()

func _on_health_component_damage_taken(_amount: int = 0) -> void:
	if is_spectator:
		return
	player_damage_taken.emit()

func get_health_component() -> PlayerHealthComponent:
	return health_component

func get_attack_controller() -> AttackController:
	return attack_controller

func get_deck_component() -> PlayerDeckComponent:
	return deck_component

func get_stats_component() -> PlayerStatsComponent:
	return stats_component

func get_movement_component() -> PlayerMovementComponent:
	return movement_component

func get_visuals_component() -> PlayerVisualsComponent:
	return visuals_component

func get_movement_speed() -> float:
	return movement_component.get_movement_speed() if movement_component else 200.0

func get_tilt_angle() -> float:
	return movement_component.get_tilt_angle() if movement_component else (sprite.rotation if sprite else 0.0)
