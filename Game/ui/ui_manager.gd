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

@export_group("Player Stats Displays")
@export var damage_label: RichTextLabel
@export var movement_speed_label: RichTextLabel
@export var attack_speed_label: RichTextLabel

@export_group("Health / Hearts System")
@export var hearts_container: Node2D
@export var health_full_sprite: Texture2D
@export var health_empty_sprite: Texture2D
@export var heart_sprite_offset: int = 12

@export_group("Notifications System")
@export var notifications_container: Control
@export var title_label: RichTextLabel
@export var subtitle_label: RichTextLabel

@export_group("Health System")
@export var health_bar: TextureProgressBar
@export var damage_bar: TextureProgressBar

var health_tween: Tween
var damage_tween: Tween
var xp_tween: Tween
var title_tween: Tween

var hearts: Array = []
var max_health: int = 0

func _ready() -> void:
	show_start_screen()

# --- ZARZĄDZANIE PANE LAMI ---

func show_start_screen() -> void:
	if hud_panel: hud_panel.hide()
	if intermission_panel: intermission_panel.hide()
	if game_over_panel: game_over_panel.hide()
	if pause_panel: pause_panel.hide()
	if notifications_container: notifications_container.hide()

func hide_start_game_label() -> void:
	if start_game_panel: start_game_panel.hide()

func show_hud() -> void:
	if start_game_panel: start_game_panel.hide()
	if hud_panel: hud_panel.show()

func show_intermission_prompt(value: bool) -> void:
	if intermission_panel:
		intermission_panel.visible = value

func show_game_over_screen() -> void:
	if game_over_panel: game_over_panel.show()

func show_pause_menu() -> void:
	if pause_panel:
		pause_panel.show()

func hide_pause_menu() -> void:
	if pause_panel:
		pause_panel.hide()

# --- SYSTEM SERDUSZEK (CZYSZCZONY I ZOPTYMALIZOWANY) ---

# --- SYSTEM PASEKA ZDROWIA (HP BAR) ---

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

	# 1. Główny pasek płynnie ubywa NATYCHMIAST (czas: 0.25s)
	if health_tween:
		health_tween.kill()

	health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", current_hp, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# 2. Pasek obrażeń (czerwony) czeka 0.2s i zjeżdża powoli za zielonym (czas: 0.4s)
	if damage_bar:
		if damage_tween:
			damage_tween.kill()

		damage_tween = create_tween()
		damage_tween.tween_interval(0.2)
		damage_tween.tween_property(damage_bar, "value", current_hp, 0.8)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

	shake_health_bar()

func shake_health_bar() -> void:
	if not health_bar or not damage_bar:
		return

	var original_pos = health_bar.position
	var shake_tween = create_tween()

	shake_tween.tween_property(health_bar, "position", original_pos + Vector2(-3, 0), 0.05)
	shake_tween.tween_property(health_bar, "position", original_pos + Vector2(3, 0), 0.075)
	shake_tween.tween_property(health_bar, "position", original_pos + Vector2(-1, 0), 0.1)
	shake_tween.tween_property(health_bar, "position", original_pos, 0.075)

func set_max_health(new_max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = new_max_hp

# --- PROGRESJA, DYSTANS I WYNIK ---

func update_experience_bar(current_xp: float, animate: bool = true) -> void:
	if not experience_bar:
		return

	if xp_tween:
		xp_tween.kill()

	if animate:
		xp_tween = create_tween()
		xp_tween.tween_property(experience_bar, "value", current_xp, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	else:
		experience_bar.value = current_xp

func extend_experience_bar(max_xp: float) -> void:
	if experience_bar:
		experience_bar.max_value = max_xp

func update_distance_label(distance: float) -> void:
	if distance_label:
		distance_label.text = "[center]" + str("%.0f" % distance) + " km"

func update_score_label(score: float) -> void:
	if score_label:
		score_label.text = "[center]" + str(int(score))

func update_upgrade_points_label(points: int) -> void:
	if upgrade_points_label:
		upgrade_points_label.text = "Points: " + str(points)

func update_stats_label(damage: int, movement_speed: int, attack_speed: int) -> void:
	if damage_label: damage_label.text = str(damage)
	if movement_speed_label: movement_speed_label.text = str(movement_speed)
	if attack_speed_label: attack_speed_label.text = str(attack_speed)


# --- TITLE / SUBTITLE ---

func show_notification(title_text: String, subtitle_text: String = "", duration: float = 2.5) -> void:
	if not notifications_container or not title_label:
		return

	title_label.text = "[center]" + title_text + "[/center]"
	if subtitle_label:
		subtitle_label.text = "[center]" + subtitle_text + "[/center]"

	if title_tween:
		title_tween.kill()

	title_tween = create_tween().set_parallel(true)

	notifications_container.pivot_offset = notifications_container.size / 2.0

	notifications_container.modulate.a = 0.0
	notifications_container.scale = Vector2(1.25, 1.25)
	notifications_container.show()

	title_tween.tween_property(notifications_container, "modulate:a", 1.0, 0.3)

	title_tween.tween_property(notifications_container, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if duration > 0.0:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_interval(duration)
		fade_out_tween.tween_property(notifications_container, "modulate:a", 0.0, 0.5)
		fade_out_tween.tween_callback(notifications_container.hide)


func hide_notification(fade_duration: float = 0.5) -> void:
	if not notifications_container or not notifications_container.visible:
		return

	if title_tween:
		title_tween.kill()

	title_tween = create_tween()
	title_tween.tween_property(notifications_container, "modulate:a", 0.0, fade_duration)
	title_tween.tween_callback(notifications_container.hide)
