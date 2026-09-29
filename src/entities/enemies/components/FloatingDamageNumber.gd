class_name FloatingDamageNumber extends Node2D

enum DamageType {
	NORMAL,
	CRITICAL,
	POISON,
	FIRE
}

@export var label: RichTextLabel

@export_group("Gravity & Arc Settings")
@export var jump_height: float = 6.0
@export var fall_distance: float = 12.0
@export var horizontal_spread: float = 14.0
@export var jump_duration: float = 0.20
@export var fall_duration: float = 0.50

func setup(amount: int, type: DamageType = DamageType.NORMAL) -> void:
	if not label:
		label = $RichTextLabel

	label.text = str(amount)

	var target_color = Color(1.0, 0.95, 0.8)
	var target_scale = Vector2.ONE

	match type:
		DamageType.NORMAL:
			target_color = Color("#bcafb6")
		DamageType.CRITICAL:
			target_color = Color(1.0, 0.25, 0.2)
			target_scale = Vector2(1.35, 1.35)
		DamageType.POISON:
			target_color = Color(0.3, 0.9, 0.3)
		DamageType.FIRE:
			target_color = Color(1.0, 0.55, 0.1)

	label.modulate = target_color
	scale = target_scale

	_animate(target_scale)

func _animate(base_scale: Vector2) -> void:
	var start_pos = global_position
	var random_x_offset = randf_range(-horizontal_spread, horizontal_spread)
	var apex_y = start_pos.y - jump_height
	var final_y = start_pos.y + fall_distance
	var total_duration = jump_duration + fall_duration

	# 1. RUCH POZIOMY (stały dryf w lewo lub w prawo)
	var tween_x = create_tween()
	tween_x.tween_property(self, "global_position:x", start_pos.x + random_x_offset, total_duration)

	# 2. RUCH PIONOWY (symulacja wyskoku i grawitacji)
	var tween_y = create_tween()
	# Faza 1: Wyskoczenie w górę (EASE_OUT wyhamowuje ruch w stronę szczytu łuku)
	tween_y.tween_property(self, "global_position:y", apex_y, jump_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Faza 2: Opadanie pod wpływem grawitacji (EASE_IN przyspiesza ruch w dół)
	tween_y.tween_property(self, "global_position:y", final_y, fall_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 3. SKALA I ZANIKANIE (soczysty "pop" na starcie i fade-out podczas opadania)
	var tween_effects = create_tween().set_parallel(true)
	
	# Pop powiększenia
	tween_effects.tween_property(self, "scale", base_scale * 1.25, 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_effects.chain().tween_property(self, "scale", base_scale, 0.12)

	# Zanikanie z lekkim opóźnieniem
	tween_effects.tween_property(self, "modulate:a", 0.0, fall_duration * 0.7)\
		.set_delay(jump_duration + (fall_duration * 0.3))

	# Usunięcie z pamięci po ukończeniu całej sekwencji
	tween_y.finished.connect(queue_free)
