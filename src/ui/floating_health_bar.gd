class_name FloatingHealthBar extends Node2D

static var global_show_bar: bool = true
static var global_show_text: bool = false

@export var show_bar: bool = true
@export var show_text: bool = true

@onready var progress_bar: TextureProgressBar = $TextureProgressBar
@onready var health_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	visible = false
	var hc = owner.get_node_or_null("HealthComponent") if owner else get_parent().get_node_or_null("HealthComponent")
	if hc and hc.has_signal("health_changed"):
		hc.health_changed.connect(_on_health_changed)

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var can_show_bar = show_bar and global_show_bar
	var can_show_text = show_text and global_show_text

	if not (can_show_bar or can_show_text) or current_hp >= max_hp or current_hp <= 0:
		visible = false
		return

	visible = true

	if progress_bar:
		progress_bar.visible = can_show_bar
		progress_bar.max_value = max_hp
		progress_bar.value = current_hp

	if health_label:
		health_label.visible = can_show_text
		health_label.text = "%d / %d" % [current_hp, max_hp]
