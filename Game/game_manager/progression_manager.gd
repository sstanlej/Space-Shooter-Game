class_name ProgressionManager extends Node

# --- Sygnały do Aktualizacji UI ---
signal experience_updated(current_xp: int, max_xp: int)
signal level_up_occurred(new_level: int, total_upgrade_points: int)
signal score_updated(new_score: float)
signal distance_updated(new_distance: float)
signal upgrade_points_changed(new_points: int)

@export_group("Progression Settings")
@export var experience_needed: int = 100
@export var experience_needed_modifier: float = 1.2

@export_group("System References")
@export var ui_manager: UIManager

var experience: int = 0
var level: int = 1
var score: float = 0.0
var distance: float = 0.0
var upgrade_points: int = 0

func _process(delta: float) -> void:
	# Dystans nalicza się tylko podczas gry (Gdy węzeł World działa)
	distance += delta
	distance_updated.emit(distance)
	if ui_manager:
		ui_manager.update_distance_label(distance)

# --- ZARZĄDZANIE PROGRESSION / RESTART ---

func reset_progress() -> void:
	experience = 0
	level = 1
	score = 0.0
	distance = 0.0
	upgrade_points = 0
	experience_needed = 100

	experience_updated.emit(experience, experience_needed)
	score_updated.emit(score)
	distance_updated.emit(distance)
	upgrade_points_changed.emit(upgrade_points)

	if ui_manager:
		# KLUCZOWE: Najpierw ustawiamy max_value paska (100), a potem jego obecną wartość (0)!
		ui_manager.extend_experience_bar(experience_needed)
		ui_manager.update_experience_bar(experience)
		ui_manager.update_score_label(score)
		ui_manager.update_distance_label(distance)
		ui_manager.update_upgrade_points_label(upgrade_points)

# --- LOGIKA DOŚWIADCZENIA I POZIOMÓW ---

func add_enemy_reward(points: float, xp: float) -> void:
	score += points
	score_updated.emit(score)
	if ui_manager:
		ui_manager.update_score_label(score)

	add_experience(int(xp))

func add_experience(amount: int) -> void:
	experience += amount

	# Najpierw przeliczamy czy nastąpił level up
	var did_level_up = check_level_up()

	# Jeśli NIE BYŁO level-upa – po prostu płynnie animujemy do nowej wartości
	if not did_level_up:
		if ui_manager:
			ui_manager.update_experience_bar(experience, true)

	experience_updated.emit(experience, experience_needed)

func check_level_up() -> bool:
	var leveled_up: bool = false

	while experience >= experience_needed:
		experience -= experience_needed
		level += 1
		experience_needed = int(experience_needed * experience_needed_modifier)
		upgrade_points += 1
		leveled_up = true

		print("[ProgressionManager] LEVEL UP! Nowy poziom: ", level)

		level_up_occurred.emit(level, upgrade_points)
		upgrade_points_changed.emit(upgrade_points)

		if ui_manager:
			# 1. Ustawiamy nowy, większy limit paska
			ui_manager.extend_experience_bar(experience_needed)
			# 2. Resetujemy wartość na sztywno BEZ ANIMACJI i zabijamy stary Tween!
			ui_manager.update_experience_bar(experience, false)
			ui_manager.update_upgrade_points_label(upgrade_points)

	return leveled_up

func spend_upgrade_point() -> bool:
	if upgrade_points > 0:
		upgrade_points -= 1
		upgrade_points_changed.emit(upgrade_points)
		if ui_manager:
			ui_manager.update_upgrade_points_label(upgrade_points)
		return true
	return false

# --- GETTERY ---

func get_experience() -> int:
	return experience

func get_level() -> int:
	return level

func get_score() -> float:
	return score

func get_distance() -> float:
	return distance

func get_upgrade_points() -> int:
	return upgrade_points
