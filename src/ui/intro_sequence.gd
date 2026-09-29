class_name IntroSequence extends Node2D

signal asteroid_impacted
signal sequence_finished

@export_group("References")
@export var earth_sprite: Sprite2D
@export var asteroid_sprite: Sprite2D
@export var debris_container: Node2D
@export var explosion_scene: PackedScene
@export var impact_particles: GPUParticles2D

@export_group("Timings & Offsets")
@export var asteroid_spawn_offset: Vector2 = Vector2(80.0, -140.0)
@export var asteroid_flight_duration: float = 2

var _debris_sprites: Array[Sprite2D] = []

func _ready() -> void:
	if asteroid_sprite:
		asteroid_sprite.visible = false
	if debris_container:
		for child in debris_container.get_children():
			if child is Sprite2D:
				child.visible = false
				_debris_sprites.append(child)

func reset_intro() -> void:
	if earth_sprite: earth_sprite.visible = true
	if asteroid_sprite: asteroid_sprite.visible = false
	for d in _debris_sprites:
		d.visible = false
	visible = true

func launch_asteroid() -> void:
	if not asteroid_sprite or not earth_sprite:
		return

	var target_pos = earth_sprite.position
	var start_pos = target_pos + asteroid_spawn_offset
	
	asteroid_sprite.position = start_pos
	asteroid_sprite.visible = true

	# Lot asteroidy z przyspieszeniem pod wpływem grawitacji
	GlobalAudio.play_asteroid_flight()
	var tween = create_tween()
	tween.tween_property(asteroid_sprite, "position", target_pos, asteroid_flight_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween.finished
	_trigger_impact()

func _trigger_impact() -> void:
	asteroid_impacted.emit()

	if earth_sprite: earth_sprite.visible = false
	if asteroid_sprite: asteroid_sprite.visible = false
	GlobalAudio.play_long_explosion()

	# 1. Kaskadowe wybuchy w miejscu kolizji
	_spawn_cluster_explosions(earth_sprite.global_position)

	# 2. Odpalenie cząsteczek
	if impact_particles:
		impact_particles.global_position = earth_sprite.global_position
		impact_particles.restart()
		impact_particles.emitting = true

	# 3. Rozrzut odłamków Ziemi
	_scatter_debris()

func _scatter_debris() -> void:
	var debris_count = _debris_sprites.size()
	if debris_count == 0:
		return

	# Dzielimy pełen obrót (TAU = 360 stopni w radianach) na równe sektory dla każdego odłamka
	var base_angle_step = TAU / debris_count

	for i in range(debris_count):
		var debris = _debris_sprites[i]
		debris.visible = true
		debris.modulate.a = 1.0

		# Kąt sektora + losowe lekkie odchylenie (+/- ~23 stopnie / 0.4 radiana)
		var angle = (i * base_angle_step) + randf_range(-0.4, 0.4)
		# Losowa odległość odlotu odłamka od środka (w pikselach)
		var distance = randf_range(80.0, 130.0)

		# Obliczenie wektora docelowego z kąta i odległości
		var target_offset = Vector2.from_angle(angle) * distance
		var fly_duration = randf_range(4.0, 5.0)

		var t = create_tween().set_parallel(true)
		# Odlot odłamka
		t.tween_property(debris, "position", target_offset, fly_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Zanikanie pod koniec
		t.tween_property(debris, "modulate:a", 0.0, fly_duration * 0.4).set_delay(fly_duration * 0.6)

func _spawn_cluster_explosions(center_pos: Vector2) -> void:
	if not explosion_scene:
		return

	# Kilka wybuchów z mikro-opóźnieniem dla soczystości uderzenia
	var offsets = [
		Vector2.ZERO,
		Vector2(12.0, -8.0),
		Vector2(-14.0, 10.0),
		Vector2(-6.0, -12.0)
	]

	for i in range(offsets.size()):
		var exp_instance = explosion_scene.instantiate() as Node2D
		if exp_instance:
			exp_instance.global_position = center_pos + offsets[i]
			get_parent().add_child(exp_instance)
		if i < offsets.size() - 1:
			await get_tree().create_timer(0.17).timeout
