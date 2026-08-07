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

func setup_hearts(initial_max_hp: int) -> void:
	max_health = initial_max_hp

	# Czyszczenie starych serduszek, jeśli restartujemy grę
	for child in hearts_container.get_children():
		child.queue_free()
	hearts.clear()

	Heart.set_textures(health_full_sprite, health_empty_sprite)

	var pixel_offset: int = 0
	for i in range(max_health):
		var heart_instance = Heart.spawn_heart()
		hearts_container.add_child(heart_instance)
		heart_instance.position.x = pixel_offset
		heart_instance.set_on(true) # Domyślnie pełne
		hearts.append(heart_instance)
		pixel_offset += heart_sprite_offset

func update_health_bar(current_hp: int) -> void:
	# Banalnie prosta i czysta logika:
	# Wszystkie serduszka z indeksem mniejszym niż current_hp są włączone (pełne), reszta wyłączona (puste)!
	for i in range(hearts.size()):
		var is_full = i < current_hp
		hearts[i].set_on(is_full)

# --- PROGRESJA, DYSTANS I WYNIK ---

func update_experience_bar(current_xp: int) -> void:
	if experience_bar:
		experience_bar.value = current_xp

func extend_experience_bar(max_xp: int) -> void:
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

	title_tween = create_tween().set_parallel(true) # Wykonujemy animacje równolegle!

	# Ustawiamy punkt pivota na środek do skalowania
	notifications_container.pivot_offset = notifications_container.size / 2.0

	# Reset do początkowych wartości
	notifications_container.modulate.a = 0.0
	notifications_container.scale = Vector2(1.25, 1.25) # Lekkie powiększenie na start!
	notifications_container.show()

	# 1. Płynne pojawianie się (Fade In)
	title_tween.tween_property(notifications_container, "modulate:a", 1.0, 0.3)

	# 2. Efekt "Punch": Zmniejszenie ze skali 1.25 do 1.0 z efektem wyhamowania
	title_tween.tween_property(notifications_container, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Sekwencja znikania (po zakończeniu powiększania)
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