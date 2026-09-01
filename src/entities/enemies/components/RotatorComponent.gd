class_name RotatorComponent extends Node

enum RotationMode {
	CONTINUOUS,  ## Stały, płynny obrót ze zdefiniowaną prędkością
	INTERVAL_BURST  ## Skokowy obrót co losowy interwał o losowy kąt (zgodnie z ruchem wskazówek zegara)
}

@export var target_sprite: CanvasItem
@export var mode: RotationMode = RotationMode.CONTINUOUS

@export_group("Continuous Mode Settings")
## Prędkość stałego obrotu w radianach na sekundę
@export var rotation_speed: float = 0.6

@export_group("Interval Burst Settings")
## Minimalny i maksymalny czas (w sekundach) pomiędzy kolejnymi obrotami
@export var min_interval: float = 1.0
@export var max_interval: float = 3.0

## Minimalny i maksymalny kąt obrotu w stopniach (obrót w prawo / zgodnie z ruchem wskazówek zegara)
@export var min_angle_deg: float = 30.0
@export var max_angle_deg: float = 90.0

## Czas trwania animacji obrotu w sekundach (ustaw 0.0, aby przeskok był natychmiastowy)
@export var step_duration: float = 0.2
@export var transition_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

var _timer: float = 0.0
var _current_target_interval: float = 0.0
var _tween: Tween

func _ready() -> void:
	if not target_sprite and owner:
		target_sprite = owner.get_node_or_null("Sprite2D")

	if mode == RotationMode.INTERVAL_BURST:
		_reset_interval_timer()

func _process(delta: float) -> void:
	if not target_sprite:
		return

	match mode:
		RotationMode.CONTINUOUS:
			target_sprite.rotate(rotation_speed * delta)

		RotationMode.INTERVAL_BURST:
			_timer += delta
			if _timer >= _current_target_interval:
				_timer = 0.0
				_execute_rotation_burst()
				_reset_interval_timer()

func _reset_interval_timer() -> void:
	_current_target_interval = randf_range(min_interval, max_interval)

func _execute_rotation_burst() -> void:
	# Losujemy kąt w stopniach i zamieniamy na radiany (dodatnie wartości = ruch wskazówek zegara)
	var random_angle_deg = randf_range(min_angle_deg, max_angle_deg)
	var target_rotation = target_sprite.rotation + deg_to_rad(random_angle_deg)

	if step_duration <= 0.0:
		target_sprite.rotation = target_rotation
		return

	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(transition_type).set_ease(ease_type)
	_tween.tween_property(target_sprite, "rotation", target_rotation, step_duration)