class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var max_level: int = 5
@export var required_weapon_id: String = ""

# Lista efektów składających się na tę kartę
@export var effects: Array[CardEffect] = []

var current_level: int = 0

func can_appear(equipped_weapon_id: String = "") -> bool:
	if max_level > 0 and current_level >= max_level:
		return false
	if not required_weapon_id.is_empty() and required_weapon_id != equipped_weapon_id:
		return false
	return true

func apply_to_player(player: Player) -> void:
	current_level += 1
	for effect in effects:
		if effect:
			effect.execute(player)
