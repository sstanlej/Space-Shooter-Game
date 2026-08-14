class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var max_level: int = 5
@export var required_weapon_id: String = ""

@export var effects: Array[CardEffect] = []

var current_level: int = 0

func can_appear(player: Player) -> bool:
	# 1. Limit poziomu
	if max_level > 0 and current_level >= max_level:
		return false

	# 2. Wymagana broń
	if not required_weapon_id.is_empty() and player:
		var equipped_id = ""
		if player.get("attack_controller") and player.attack_controller and player.attack_controller.equipped_weapon:
			equipped_id = player.attack_controller.equipped_weapon.weapon_id
		if required_weapon_id != equipped_id:
			return false

	# 3. Warunki konkretnych efektów (np. czy gracz potrzebuje leczenia)
	for effect in effects:
		if effect and not effect.can_appear(player):
			return false

	return true

func apply_to_player(player: Player) -> void:
	current_level += 1
	for effect in effects:
		if effect:
			effect.execute(player)
