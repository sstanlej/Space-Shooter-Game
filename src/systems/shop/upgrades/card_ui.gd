class_name CardUI extends Control

@export var title_label: RichTextLabel
@export var description_label: RichTextLabel
@export var icon_rect: TextureRect
@export var background_rect: TextureRect

var card_data: UpgradeCardData
var is_selected: bool = false
var tween: Tween

const RARITY_COLORS = {
	UpgradeCardData.Rarity.COMMON: "#E0E0E0",
	UpgradeCardData.Rarity.RARE: "#4DA6FF",
	UpgradeCardData.Rarity.EPIC: "#BF55EC",
	UpgradeCardData.Rarity.LEGENDARY: "#FFD700"
}

func setup(data: UpgradeCardData) -> void:
	card_data = data
	if not card_data:
		return

	var color_hex = RARITY_COLORS.get(card_data.rarity, "#FFFFFF")

	if title_label:
		title_label.text = "[center][color=" + color_hex + "]" + card_data.title + "[/color][/center]"
	if description_label:
		description_label.text = "[center]" + card_data.description + "[/center]"
	if icon_rect and card_data.icon:
		icon_rect.texture = card_data.icon

	set_selected(false, true)

func set_selected(selected: bool, immediate: bool = false) -> void:
	is_selected = selected
	var target_scale = Vector2(1.1, 1.1) if is_selected else Vector2(1.0, 1.0)
	var target_modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.65, 0.65, 0.65, 0.85)

	if tween:
		tween.kill()

	if immediate:
		scale = target_scale
		modulate = target_modulate
		return

	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.15)
	tween.tween_property(self, "modulate", target_modulate, 0.15)