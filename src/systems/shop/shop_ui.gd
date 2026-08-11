class_name ShopUI extends Control

signal shop_closed

@export_group("System References")
@export var game_manager: GameManager
@export var progression_manager: ProgressionManager
@export var player: Player

@export_group("UI Elements")
@export var description_label: RichTextLabel
@export var selected_icon: Node2D # Sprite2D lub Control wskaźnika
@export var options_container: Control # Węzeł-rodzic opcji ulepszeń

@export_group("Animation Settings")
@export var closed_y: float = -300.0
@export var open_y: float = 0.0

var options: Array = []
var current_option: PlayerUpgrade
var selected_index: int = 0
var active: bool = false
var tween: Tween

func _ready() -> void:
	# Ukrywamy sklep na starcie
	position.y = closed_y
	hide()

	# Pobieramy opcje ulepszeń z kontenera
	if options_container:
		options = options_container.get_children()

func _process(_delta: float) -> void:
	if not active:
		return

	# Nawigacja w lewo / prawo
	if Input.is_action_just_pressed("right") and selected_index < options.size() - 1:
		selected_index += 1
		update_selected_option()

	if Input.is_action_just_pressed("left") and selected_index > 0:
		selected_index -= 1
		update_selected_option()

	# Kupowanie wybranego ulepszenia
	if Input.is_action_just_pressed("attack"):
		try_buy_selected_upgrade()

	# Wyjście ze sklepu (np. klawisz 'shop' / 'B' lub ESC)
	if Input.is_action_just_pressed("shop") or Input.is_action_just_pressed("pause"):
		game_manager.close_shop()

# --- OTWIERANIE I ZAMYKANIE SKLEPU ---

func show_shop() -> void:
	show()
	update_player_stats_display()
	selected_index = 0
	update_selected_option()

	await move_open()
	active = true
	print("[ShopUI] Sklep otwarty")

func hide_shop() -> void:
	active = false
	await move_close()
	hide()
	shop_closed.emit()
	print("[ShopUI] Sklep zamknięty")

# --- LOGIKA KUPNA I ULEPSZEŃ ---

func update_selected_option() -> void:
	if options.size() == 0:
		return

	current_option = options[selected_index] as PlayerUpgrade

	if selected_icon and current_option:
		selected_icon.global_position = current_option.global_position

	update_description_label()

func try_buy_selected_upgrade() -> void:
	if not current_option or not player:
		return

	# Sprawdzamy czy mamy wystarczająco punktów ulepszeń!
	if progression_manager and progression_manager.spend_upgrade_point():
		current_option.affect_player(player)
		update_player_stats_display()
		# GlobalAudio.play_crash()
		print("[ShopUI] Zakupiono ulepszenie: ", current_option.name)

		# Jeśli po zakupie brakuje punktów, możemy automatycznie poinformować gracza
		if progression_manager.get_upgrade_points() <= 0:
			print("[ShopUI] Brak punktów ulepszeń!")
	else:
		print("[ShopUI] Nie masz wystarczająco punktów ulepszeń!")

func update_description_label() -> void:
	if description_label and current_option:
		description_label.text = "[center]" + current_option.description

func update_player_stats_display() -> void:
	if not player or not game_manager or not game_manager.ui_manager:
		return

	var stats = player.stats_component
	var atk_ctrl = player.get_attack_controller()

	var base_dmg = atk_ctrl.equipped_weapon.base_damage if atk_ctrl and atk_ctrl.equipped_weapon else 1.0
	var base_atk_spd = atk_ctrl.equipped_weapon.base_attack_speed if atk_ctrl and atk_ctrl.equipped_weapon else 3.0

	var player_damage: int = int(stats.get_final_damage(base_dmg)) if stats else int(base_dmg)
	var player_attack_speed: int = int(stats.get_final_attack_speed(base_atk_spd)) if stats else int(base_atk_spd)
	var player_speed: int = int(player.get_movement_speed())

	game_manager.ui_manager.update_stats_label(player_damage, player_speed, player_attack_speed)
# --- ANIMACJE TWEEN ---

func move_open() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", open_y, 0.5)
	await tween.finished

func move_close() -> void:
	reset_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", closed_y, 0.5)
	await tween.finished

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
