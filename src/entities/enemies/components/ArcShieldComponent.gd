class_name ArcShieldComponent extends Area2D

signal shield_damaged(current_hp: int)
signal shield_broken

@export_group("Shield Stats")
@export var is_indestructible: bool = false
@export var max_shield_health: int = 20

@export_group("Visuals")
@export var shield_sprite: CanvasItem

var current_shield_health: int
var hit_tween: Tween
var is_broken: bool = false

func _ready() -> void:
	current_shield_health = max_shield_health
	if not shield_sprite and owner:
		shield_sprite = get_node_or_null("Sprite2D")

func damage(amount: int) -> void:
	if is_broken:
		return

	trigger_hit_visual()

	if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_enemy_hit"):
		GlobalAudio.play_enemy_hit()

	if is_indestructible:
		return

	current_shield_health = max(0, current_shield_health - amount)
	shield_damaged.emit(current_shield_health)

	if current_shield_health <= 0:
		break_shield()

func trigger_hit_visual() -> void:
	if not shield_sprite:
		return

	if hit_tween and hit_tween.is_running():
		hit_tween.kill()

	shield_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	hit_tween = create_tween()
	hit_tween.tween_property(shield_sprite, "modulate", Color.WHITE, 0.1)

func break_shield() -> void:
	is_broken = true
	shield_broken.emit()

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)

	if shield_sprite:
		var tw = create_tween()
		tw.tween_property(shield_sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(shield_sprite.hide)