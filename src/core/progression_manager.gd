class_name ProgressionManager extends Node

signal experience_updated(current_xp: int, max_xp: int)
signal level_up_occurred(new_level: int, total_upgrade_points: int)
signal score_updated(new_score: float)
signal distance_updated(new_distance: float)
signal upgrade_points_changed(new_points: int)

@export_group("Progression Tuning")
@export var base_experience_needed: int = 100
@export var experience_needed_modifier: float = 1.25

@export_group("System References")
@export var ui_manager: UIManager
@export var player: Player # <-- Referencja do gracza (do pełnego leczenia)

var experience: int = 0
var experience_needed: int = 100
var level: int = 1
var score: float = 0.0
var distance: float = 0.0
var upgrade_points: int = 0

func _process(delta: float) -> void:
	distance += delta
	distance_updated.emit(distance)
	if ui_manager and ui_manager.has_method("update_distance_label"):
		ui_manager.update_distance_label(distance)

# --- RESTART / INICJALIZACJA ---

func reset_progress() -> void:
	experience = 0
	level = 1
	score = 0.0
	distance = 0.0
	upgrade_points = 0
	experience_needed = base_experience_needed

	experience_updated.emit(experience, experience_needed)
	score_updated.emit(score)
	distance_updated.emit(distance)
	upgrade_points_changed.emit(upgrade_points)

	if ui_manager:
		if ui_manager.has_method("extend_experience_bar"):
			ui_manager.extend_experience_bar(experience_needed)
		if ui_manager.has_method("update_experience_bar"):
			ui_manager.update_experience_bar(experience, false)
		if ui_manager.has_method("update_experience_label"):
			ui_manager.update_experience_label(level, experience, experience_needed)
		if ui_manager.has_method("update_score_label"):
			ui_manager.update_score_label(score)
		if ui_manager.has_method("update_distance_label"):
			ui_manager.update_distance_label(distance)
		if ui_manager.has_method("update_upgrade_points_label"):
			ui_manager.update_upgrade_points_label(upgrade_points)

# --- EXP, WYNIK I LEVEL UP ---

func add_enemy_reward(points: float, xp: float) -> void:
	score += points
	score_updated.emit(score)
	if ui_manager and ui_manager.has_method("update_score_label"):
		ui_manager.update_score_label(score)

	add_experience(int(xp))

func add_experience(amount: int) -> void:
	experience += amount
	var leveled_up = check_level_up()

	if not leveled_up and ui_manager and ui_manager.has_method("update_experience_bar"):
		ui_manager.update_experience_bar(experience, true)
		ui_manager.update_experience_label(level, experience, experience_needed)

	experience_updated.emit(experience, experience_needed)

func add_xp(amount: float) -> void:
	add_experience(int(amount))

func check_level_up() -> bool:
	if experience < experience_needed:
		return false

	var levels_gained: int = 0
	var start_needed: int = experience_needed

	# Przeliczamy wszystkie poziomy w pętli
	while experience >= experience_needed:
		experience -= experience_needed
		level += 1
		experience_needed = int(experience_needed * experience_needed_modifier)
		upgrade_points += 1
		levels_gained += 1

	print("[ProgressionManager] Level up! +%d lvl -> Aktualny Poziom: %d (Punkty: %d)" % [levels_gained, level, upgrade_points])

	# 1. Pełne uleczenie gracza po awansie
	if player and player.health_component:
		player.health_component.heal(player.health_component.get_max_health())

	level_up_occurred.emit(level, upgrade_points)
	upgrade_points_changed.emit(upgrade_points)

	if ui_manager:
		if ui_manager.has_method("update_upgrade_points_label"):
			ui_manager.update_upgrade_points_label(upgrade_points)
		if ui_manager.has_method("animate_level_up"):
			ui_manager.animate_level_up(start_needed, level, experience_needed, experience, levels_gained)

	return true

func add_upgrade_points(amount: int = 1) -> void:
	upgrade_points += amount
	upgrade_points_changed.emit(upgrade_points)
	if ui_manager and ui_manager.has_method("update_upgrade_points_label"):
		ui_manager.update_upgrade_points_label(upgrade_points)

func spend_upgrade_point() -> bool:
	if upgrade_points > 0:
		upgrade_points -= 1
		upgrade_points_changed.emit(upgrade_points)
		if ui_manager and ui_manager.has_method("update_upgrade_points_label"):
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