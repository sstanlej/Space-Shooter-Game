class_name UIManager extends CanvasLayer

@export_group("UI Panels")
@export var hud_panel: Control
@export var intermission_panel: Control
@export var shop_ui: ShopUI
@export var start_game_panel: Control
@export var game_over_panel: Control
@export var pause_panel: Control

@export_group("HUD Displays")
@export var score_label: RichTextLabel
@export var distance_label: RichTextLabel
@export var upgrade_points_label: RichTextLabel
@export var experience_bar: TextureProgressBar
@export var experience_label: RichTextLabel 
@export var enemies_left_label: RichTextLabel
@export var card_controls_label: RichTextLabel
@export var exp_particles: GPUParticles2D

@export_group("Notifications System")
@export var notifications_container: Control
@export var title_label: RichTextLabel
@export var subtitle_label: RichTextLabel

@export_group("Health System")
@export var health_bar: TextureProgressBar
@export var damage_bar: TextureProgressBar

@export_group("Game Over Displays")
@export var final_wave_label: RichTextLabel
@export var final_score_label: RichTextLabel
@export var final_distance_label: RichTextLabel

var health_tween: Tween
var shake_tween: Tween
var health_bar_base_pos: Vector2 = Vector2.ZERO
var damage_tween: Tween

var xp_tween: Tween
var title_tween: Tween
var enemies_label_tween: Tween
var controls_label_tween: Tween
var is_leveling_up: bool = false

func _ready() -> void:
	if health_bar:
		health_bar_base_pos = health_bar.position
	show_start_screen()

func show_start_screen() -> void:
	if hud_panel: hud_panel.hide()
	if intermission_panel: intermission_panel.hide()
	if game_over_panel: game_over_panel.hide()
	if pause_panel: pause_panel.hide()
	if notifications_container: notifications_container.hide()
	if enemies_left_label:
		enemies_left_label.modulate.a = 0.0
		enemies_left_label.hide()
	if card_controls_label:
		card_controls_label.modulate.a = 0.0
		card_controls_label.hide()

func hide_start_game_label() -> void:
	if start_game_panel: start_game_panel.hide()

func show_hud() -> void:
	if start_game_panel: start_game_panel.hide()
	if hud_panel: hud_panel.show()

func hide_hud() -> void:
	if hud_panel: hud_panel.hide()

func show_intermission_prompt(value: bool) -> void:
	if intermission_panel:
		intermission_panel.visible = value

func show_game_over_screen() -> void:
	if game_over_panel: game_over_panel.show()

func show_pause_menu() -> void:
	if pause_panel: pause_panel.show()

func hide_pause_menu() -> void:
	if pause_panel: pause_panel.hide()

func setup_health_bar(max_hp: int, current_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	if damage_bar:
		damage_bar.max_value = max_hp
		damage_bar.value = current_hp

func update_health_bar(current_hp: int) -> void:
	if not health_bar:
		return

	var old_hp = int(health_bar.value)
	if current_hp == old_hp:
		return

	if health_tween: health_tween.kill()
	if damage_tween: damage_tween.kill()

	if current_hp < old_hp:
		if damage_bar:
			damage_bar.modulate = Color(1.0, 0.25, 0.25, 1.0)
			damage_bar.value = old_hp

		health_tween = create_tween()
		health_tween.tween_property(health_bar, "value", current_hp, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

		if damage_bar:
			damage_tween = create_tween()
			damage_tween.tween_interval(0.2)
			damage_tween.tween_property(damage_bar, "value", current_hp, 0.6)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)

		shake_health_bar()
	else:
		if damage_bar:
			damage_bar.modulate = Color(0.3, 1.0, 0.45, 1.0)
			damage_tween = create_tween()
			damage_tween.tween_property(damage_bar, "value", current_hp, 0.15)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)

		health_tween = create_tween()
		health_tween.tween_property(health_bar, "value", current_hp, 0.45)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

		if damage_bar:
			health_tween.tween_callback(func(): damage_bar.modulate = Color(1.0, 0.25, 0.25, 1.0))

func shake_health_bar() -> void:
	if not health_bar:
		return

	if health_bar_base_pos == Vector2.ZERO:
		health_bar_base_pos = health_bar.position

	if shake_tween and shake_tween.is_running():
		shake_tween.kill()

	health_bar.position = health_bar_base_pos

	shake_tween = create_tween()
	shake_tween.tween_property(health_bar, "position", health_bar_base_pos + Vector2(-3, 0), 0.04)
	shake_tween.tween_property(health_bar, "position", health_bar_base_pos + Vector2(3, 0), 0.06)
	shake_tween.tween_property(health_bar, "position", health_bar_base_pos + Vector2(-1, 0), 0.06)
	shake_tween.tween_property(health_bar, "position", health_bar_base_pos, 0.04)

func update_experience_bar(current_xp: float, animate: bool = true) -> void:
	if not experience_bar:
		return
	if is_leveling_up:
		return

	if xp_tween and xp_tween.is_running():
		xp_tween.kill()

	if animate:
		xp_tween = create_tween()
		xp_tween.tween_property(experience_bar, "value", current_xp, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	else:
		experience_bar.value = current_xp

func animate_level_up(old_max_xp: int, new_level: int, new_max_xp: int, current_xp: int, levels_gained: int = 1) -> void:
	if not experience_bar:
		return

	is_leveling_up = true
	if xp_tween and xp_tween.is_running():
		xp_tween.kill()

	# Cząsteczki i dźwięk
	play_level_up_effect()

	# Odpalenie kaskady unoszących się napisów LEVEL UP!
	for i in range(levels_gained):
		var delay = i * 0.12
		var offset_x = (i - (levels_gained - 1) / 2.0) * 10.0 if levels_gained > 1 else 0.0
		spawn_floating_level_up(delay, offset_x)

	xp_tween = create_tween()
	experience_bar.max_value = old_max_xp

	# FAZA 1: Dobicie do końca
	xp_tween.tween_property(experience_bar, "value", float(old_max_xp), 0.12)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# FAZA 2: Kulminacja (Flash paska + Pop etykiety)
	xp_tween.tween_callback(func():
		experience_bar.modulate = Color(2.5, 2.5, 2.5, 1.0)
		experience_bar.pivot_offset = experience_bar.size / 2.0

		var bar_pop = create_tween()
		bar_pop.tween_property(experience_bar, "scale", Vector2(1.06, 1.16), 0.08)
		bar_pop.tween_property(experience_bar, "scale", Vector2.ONE, 0.16)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

		if experience_label:
			experience_label.pivot_offset = experience_label.size / 2.0
			experience_label.text = "[center]LVL: %d    0 / %d[/center]" % [new_level, new_max_xp]
			var lbl_pop = create_tween()
			lbl_pop.tween_property(experience_label, "scale", Vector2(1.25, 1.25), 0.08)
			lbl_pop.tween_property(experience_label, "scale", Vector2.ONE, 0.16)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)

		experience_bar.max_value = new_max_xp
		experience_bar.value = 0
	)

	# FAZA 3: Powrót koloru do normy
	xp_tween.tween_property(experience_bar, "modulate", Color.WHITE, 0.1)

	# FAZA 4: Wlanie nadmiarowego EXP
	xp_tween.tween_property(experience_bar, "value", float(current_xp), 0.35)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# FAZA 5: Odblokowanie flagi i aktualizacja etykiety
	xp_tween.tween_callback(func():
		update_experience_label(new_level, current_xp, new_max_xp)
		is_leveling_up = false
	)
func spawn_floating_level_up(delay: float = 0.0, offset_x: float = 0.0) -> void:
	if not experience_bar or not hud_panel:
		return

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font_path = "res://assets/fonts/Pixeled.ttf"
	if ResourceLoader.exists(font_path):
		var font_res = load(font_path)
		label.add_theme_font_override("normal_font", font_res)
		label.add_theme_font_size_override("normal_font_size", 7)

	label.text = "[center][color=#e4f1f8]LEVEL UP![/color][/center]"

	var label_w: float = 64.0
	var label_h: float = 12.0
	label.custom_minimum_size = Vector2(label_w, label_h)
	label.size = Vector2(label_w, label_h)

	hud_panel.add_child(label)

	var bar_center_x = experience_bar.position.x + (experience_bar.size.x / 2.0)
	var start_pos = Vector2(bar_center_x - (label_w / 2.0) + offset_x, experience_bar.position.y - 2.0)

	label.position = start_pos
	label.modulate.a = 1.0
	label.z_index = 10

	var float_tween = create_tween()
	if delay > 0.0:
		label.modulate.a = 0.0
		float_tween.tween_interval(delay)
		float_tween.tween_callback(func(): label.modulate.a = 1.0)

	# Wymuszamy pełny tryb równoległy dla wszystkich kolejnych właściwości:
	float_tween.set_parallel(true)

	# 1. Agresywny wystrzał i wyhamowanie
	float_tween.tween_property(label, "position:y", start_pos.y - 24.0, 0.75)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)

	# 2. Zanikanie dokładnie w trakcie lotu (znika całkowicie w 0.38s)
	float_tween.tween_property(label, "modulate:a", 0.0, 0.5)\
		.set_delay(0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# 3. chain() czeka na zakończenie dłuższego z nich (0.48s) i bezpiecznie usuwa obiekt
	float_tween.chain().tween_callback(label.queue_free)

func play_level_up_effect() -> void:
	if exp_particles:
		exp_particles.restart()
		exp_particles.emitting = true

	if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_levelup"):
		GlobalAudio.play_levelup()

func extend_experience_bar(max_xp: float) -> void:
	if experience_bar:
		experience_bar.max_value = max_xp

func update_experience_label(level: int, current_xp: float, max_xp: float) -> void:
	if experience_label:
		experience_label.text = "[center]LVL [color=#e4f1f8]%d[/color]    %d / %d[/center]" % [level, int(current_xp), int(max_xp)]

func update_distance_label(distance: float) -> void:
	if distance_label:
		distance_label.text = "[center]" + str("%.0f" % distance) + " km"

func update_score_label(score: float) -> void:
	if score_label:
		score_label.text = "[center]" + str(int(score))

func update_upgrade_points_label(points: int) -> void:
	if upgrade_points_label:
		upgrade_points_label.text = "Points: " + str(points)

func show_notification(title_text: String, subtitle_text: String = "", duration: float = 2.5) -> void:
	if not notifications_container or not title_label:
		return

	title_label.text = "[center]" + title_text + "[/center]"
	if subtitle_label:
		subtitle_label.text = "[center]" + subtitle_text + "[/center]"

	if title_tween: title_tween.kill()
	title_tween = create_tween()

	notifications_container.pivot_offset = notifications_container.size / 2.0
	notifications_container.modulate.a = 0.0
	notifications_container.scale = Vector2(1.25, 1.25)
	notifications_container.show()

	var appear_tween = title_tween.parallel()
	appear_tween.tween_property(notifications_container, "modulate:a", 1.0, 0.3)
	appear_tween.tween_property(notifications_container, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	if duration > 0.0:
		title_tween.tween_interval(duration)
		title_tween.tween_property(notifications_container, "modulate:a", 0.0, 0.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		title_tween.tween_callback(notifications_container.hide)

func hide_notification(fade_duration: float = 0.5) -> void:
	if not notifications_container or not notifications_container.visible:
		return
	if title_tween: title_tween.kill()
	title_tween = create_tween()
	title_tween.tween_property(notifications_container, "modulate:a", 0.0, fade_duration)
	title_tween.tween_callback(notifications_container.hide)

func update_game_over_stats(wave: int, score: float, distance: float) -> void:
	if final_wave_label:
		final_wave_label.text = "[center][color=gray]Reached Wave: [/color][color=gold]" + str(wave) + "[/color][/center]"
	if final_score_label:
		final_score_label.text = "[center][color=gray]Final Score: [/color][color=gold]" + str(int(score)) + "[/color][/center]"
	if final_distance_label:
		final_distance_label.text = "[center][color=gray]Distance: [/color][color=gold]" + str(int(distance)) + " km[/color][/center]"

func update_enemies_left_label(count: int) -> void:
	if enemies_left_label:
		enemies_left_label.text = "[right]ENEMIES LEFT: [color=gold]" + str(count) + "[/color][/right]"

func fade_in_label(label: RichTextLabel, label_tween: Tween, duration: float = 0.5) -> void:
	if not label:
		return
	if label_tween: label_tween.kill()
	label.show()
	label_tween = create_tween()
	label_tween.tween_property(label, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func fade_out_label(label: RichTextLabel, label_tween: Tween, duration: float = 0.5) -> void:
	if not label:
		return
	if label_tween: label_tween.kill()
	label_tween = create_tween()
	label_tween.tween_property(label, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	label_tween.tween_callback(label.hide)