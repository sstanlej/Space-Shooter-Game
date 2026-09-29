class_name IntroSequence extends Node2D

signal asteroid_impacted
signal sequence_finished

@export_group("External Scene References")
@export var player: Player
@export var camera_frame: CameraFrame

@export_group("Internal References")
@export var earth_sprite: Sprite2D
@export var asteroid_sprite: Sprite2D
@export var debris_container: Node2D
@export var explosion_scene: PackedScene
@export var impact_particles: GPUParticles2D

@export_group("Asteroid Settings")
@export var asteroid_spawn_offset: Vector2 = Vector2(80.0, -140.0)
@export var asteroid_flight_duration: float = 2.0

@export_group("Player Liftoff Settings")
@export var player_launch_delay: float = 0.7
@export var player_target_x: float = 20.0
@export var player_escape_duration: float = 3.0

@export_group("Camera Shake Settings")
@export var warning_shake_intensity: float = 1.5
@export var warning_shake_duration: float = 2.0
@export var impact_shake_intensity: float = 12.0
@export var impact_shake_duration: float = 1.5

@export_group("Debris Settings")
@export var debris_min_distance: float = 80.0
@export var debris_max_distance: float = 130.0
@export var debris_angle_spread: float = 0.4
@export var debris_duration_min: float = 4.0
@export var debris_duration_max: float = 5.0
@export var debris_fade_delay_ratio: float = 0.6
@export var debris_fade_duration_ratio: float = 0.4

@export_group("Explosion Settings")
@export var explosion_interval: float = 0.17
@export var explosion_offsets: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(12.0, -8.0),
	Vector2(-14.0, 10.0),
	Vector2(-6.0, -12.0)
]

@export_group("Transition Delays")
@export var post_impact_delay: float = 1.5

var _debris_sprites: Array[Sprite2D] = []

func _ready() -> void:
	_collect_debris_sprites()
	reset_intro()

func reset_intro() -> void:
	if earth_sprite:
		earth_sprite.visible = true
	if asteroid_sprite:
		asteroid_sprite.visible = false
	for debris in _debris_sprites:
		debris.visible = false
	visible = true

func play_sequence() -> void:
	_trigger_warning_shake()
	var asteroid_tween = _animate_asteroid_flight()
	
	_schedule_player_liftoff()
	
	await asteroid_tween.finished
	_trigger_impact()
	
	await get_tree().create_timer(post_impact_delay).timeout
	await _transition_camera_to_game()
	
	sequence_finished.emit()

func _collect_debris_sprites() -> void:
	_debris_sprites.clear()
	if not debris_container:
		return
	for child in debris_container.get_children():
		if child is Sprite2D:
			child.visible = false
			_debris_sprites.append(child)

func _trigger_warning_shake() -> void:
	if camera_frame:
		camera_frame.shake(warning_shake_intensity, warning_shake_duration)

func _animate_asteroid_flight() -> Tween:
	if not asteroid_sprite or not earth_sprite:
		return create_tween()

	var target_pos = earth_sprite.position
	var start_pos = target_pos + asteroid_spawn_offset

	asteroid_sprite.position = start_pos
	asteroid_sprite.visible = true

	GlobalAudio.play_asteroid_flight()
	var tween = create_tween()
	tween.tween_property(asteroid_sprite, "position", target_pos, asteroid_flight_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween

func _schedule_player_liftoff() -> void:
	await get_tree().create_timer(player_launch_delay).timeout
	if player and earth_sprite:
		_setup_player_position()
		_activate_player_liftoff_trail()
		_animate_player_escape()

func _setup_player_position() -> void:
	player.global_position = earth_sprite.global_position
	player.visible = true

func _activate_player_liftoff_trail() -> void:
	var visuals = player.get_node_or_null("PlayerVisualsComponent")
	if visuals and visuals.has_method("activate_liftoff_trail"):
		visuals.activate_liftoff_trail()

func _animate_player_escape() -> Tween:
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", player_target_x, player_escape_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween

func _trigger_impact() -> void:
	asteroid_impacted.emit()

	if earth_sprite:
		earth_sprite.visible = false
	if asteroid_sprite:
		asteroid_sprite.visible = false

	GlobalAudio.play_long_explosion()
	_trigger_impact_shake()
	_trigger_impact_particles()
	_spawn_cluster_explosions(earth_sprite.global_position if earth_sprite else global_position)
	_scatter_debris()

func _trigger_impact_shake() -> void:
	if camera_frame:
		camera_frame.shake(impact_shake_intensity, impact_shake_duration)

func _trigger_impact_particles() -> void:
	if impact_particles and earth_sprite:
		impact_particles.global_position = earth_sprite.global_position
		impact_particles.restart()
		impact_particles.emitting = true

func _spawn_cluster_explosions(center_pos: Vector2) -> void:
	if not explosion_scene:
		return

	for i in range(explosion_offsets.size()):
		_spawn_single_explosion(center_pos + explosion_offsets[i])
		if i < explosion_offsets.size() - 1:
			await get_tree().create_timer(explosion_interval).timeout

func _spawn_single_explosion(pos: Vector2) -> void:
	var exp_instance = explosion_scene.instantiate() as Node2D
	if not exp_instance:
		return
	exp_instance.global_position = pos
	get_parent().add_child(exp_instance)

func _scatter_debris() -> void:
	var debris_count = _debris_sprites.size()
	if debris_count == 0:
		return

	var angle_step = TAU / debris_count
	for i in range(debris_count):
		var debris = _debris_sprites[i]
		var angle = (i * angle_step) + randf_range(-debris_angle_spread, debris_angle_spread)
		_animate_debris_piece(debris, angle)

func _animate_debris_piece(debris: Sprite2D, angle: float) -> void:
	debris.visible = true
	debris.modulate.a = 1.0

	var distance = randf_range(debris_min_distance, debris_max_distance)
	var target_offset = Vector2.from_angle(angle) * distance
	var fly_duration = randf_range(debris_duration_min, debris_duration_max)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(debris, "position", target_offset, fly_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		debris, 
		"modulate:a", 
		0.0, 
		fly_duration * debris_fade_duration_ratio
	).set_delay(fly_duration * debris_fade_delay_ratio)

func _transition_camera_to_game() -> Signal:
	if camera_frame:
		var cam_tween = camera_frame.move_to_game_view()
		return cam_tween.finished
	return get_tree().process_frame
