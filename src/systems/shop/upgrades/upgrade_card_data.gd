class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CardType { STAT, WEAPON, USABLE, INSTANT }
enum StatType { NONE, DAMAGE, SPEED, ATTACK_SPEED, PROJECTILES, MAX_HEALTH, AGILITY }
enum UsableType { NONE, SHIELD }

@export_group("Card Metadata")
@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.STAT

@export_group("Stat Settings")
@export var stat_type: StatType = StatType.NONE
@export var stat_value_per_level: float = 1.0
@export var base_level: int = 1
@export var max_level: int = 5

@export_group("Weapon Settings")
@export var weapon_data: WeaponData

@export_group("Usable Settings")
@export var usable_type: UsableType = UsableType.NONE
@export var max_charges: int = 3

@export_group("Special Effects")
@export var required_weapon_id: String = ""
@export var effects: Array[CardEffect] = []

func get_stat_bonus(current_level: int) -> float:
	return maxf(0.0, float(current_level - base_level)) * stat_value_per_level

func can_appear(player: Player) -> bool:
	if not player:
		return true

	var deck = player.get_deck_component()
	if not deck:
		return true

	if card_type == CardType.STAT and max_level > 0:
		if deck.get_card_level(self) >= max_level:
			return false

	if card_type == CardType.USABLE and usable_type == UsableType.SHIELD:
		if player.health_component and player.health_component.shield_charges >= max_charges:
			return false

	if not required_weapon_id.is_empty():
		var equipped_id = deck.equipped_weapon.weapon_id if deck.equipped_weapon else ""
		if required_weapon_id != equipped_id:
			return false

	for effect in effects:
		if effect and not effect.can_appear(player):
			return false

	return true

func apply_to_player(player: Player) -> void:
	if not player:
		return

	var deck = player.get_deck_component()
	if deck:
		deck.apply_card(self)

	for effect in effects:
		if effect:
			effect.execute(player)
