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
@export var enemies_left_label: RichTextLabel

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

@export_group("Game Over Displays")
@export var final_wave_label: RichTextLabel
@export var final_score_label: RichTextLabel
@export var final_distance_label: RichTextLabel

var health_tween: Tween
var damage_tween: Tween
var xp_tween: Tween
var title_tween: Tween
var enemies_label_tween: Tween

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
	if enemies_left_label:
		enemies_left_label.modulate.a = 0.0
		enemies_left_label.hide()

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

	var old_hp = int(health_bar.value)
	
	# Jeśli zdrowie się nie zmieniło (np. wybrano ulepszenie ataku) -> nic nie robimy!
	if current_hp == old_hp:
		return

	if health_tween:
		health_tween.kill()
	if damage_tween:
		damage_tween.kill()

	if current_hp < old_hp:
		# ==========================================
		# OTRZYMANIE OBRAŻEŃ (DAMAGE)
		# ==========================================
		if damage_bar:
			damage_bar.modulate = Color(1.0, 0.25, 0.25, 1.0) # Czerwony kolor śladu
			damage_bar.value = old_hp

		# Główny pasek natychmiast ubywa
		health_tween = create_tween()
		health_tween.tween_property(health_bar, "value", current_hp, 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

		# Czerwony pasek czeka 0.2s i powoli zjeżdża za zielonym
		if damage_bar:
			damage_tween = create_tween()
			damage_tween.tween_interval(0.2)
			damage_tween.tween_property(damage_bar, "value", current_hp, 0.6)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)

		shake_health_bar()

	else:
		if damage_bar:
			damage_bar.modulate = Color(0.3, 1.0, 0.45, 1.0) # Jasnozielony kolor leczenia
			damage_tween = create_tween()
			damage_tween.tween_property(damage_bar, "value", current_hp, 0.15)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)

		# Główny pasek płynnie dopływa do nowej wartości
		health_tween = create_tween()
		health_tween.tween_property(health_bar, "value", current_hp, 0.45)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

		# Po zakończeniu animacji leczenia przywracamy domyślny czerwony odcień
		if damage_bar:
			health_tween.tween_callback(func(): damage_bar.modulate = Color(1.0, 0.25, 0.25, 1.0))

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

func update_stats_label(damage_lvl: int, movement_speed_lvl: int, attack_speed_lvl: int) -> void:
	if damage_label: 
		damage_label.text = str(damage_lvl)
	if movement_speed_label: 
		movement_speed_label.text = str(movement_speed_lvl)
	if attack_speed_label: 
		attack_speed_label.text = str(attack_speed_lvl)

# --- TITLE / SUBTITLE ---

func show_notification(title_text: String, subtitle_text: String = "", duration: float = 2.5) -> void:
	if not notifications_container or not title_label:
		return

	title_label.text = "[center]" + title_text + "[/center]"
	if subtitle_label:
		subtitle_label.text = "[center]" + subtitle_text + "[/center]"

	if title_tween:
		title_tween.kill()

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

	if title_tween:
		title_tween.kill()

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
		enemies_left_label.text = "[center]ENEMIES LEFT: [color=gold]" + str(count) + "[/color][/center]"

func show_enemies_left_label(fade_duration: float = 0.4) -> void:
	if not enemies_left_label:
		return

	if enemies_label_tween:
		enemies_label_tween.kill()

	enemies_left_label.show()
	enemies_label_tween = create_tween()
	enemies_label_tween.tween_property(enemies_left_label, "modulate:a", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func hide_enemies_left_label(fade_duration: float = 0.4) -> void:
	if not enemies_left_label:
		return

	if enemies_label_tween:
		enemies_label_tween.kill()

	enemies_label_tween = create_tween()
	enemies_label_tween.tween_property(enemies_left_label, "modulate:a", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	enemies_label_tween.tween_callback(enemies_left_label.hide)