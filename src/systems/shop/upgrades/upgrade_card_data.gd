class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CardType { STAT, WEAPON, USABLE, INSTANT }
enum StatType { NONE, DAMAGE, SPEED, ATTACK_SPEED, PROJECTILES, MAX_HEALTH, AGILITY }

@export_group("Card Metadata")
@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.STAT

@export_group("Stat Settings (Tylko dla CardType.STAT)")
## Wybierz statystykę, którą ta karta ulepsza (Effects zostaw puste!)
@export var stat_type: StatType = StatType.NONE
@export var max_level: int = 5

@export_group("Weapon Settings (Tylko dla CardType.WEAPON)")
@export var weapon_data: WeaponData

@export_group("Usable Settings (Tylko dla CardType.USABLE - np. Tarcza)")
@export var max_charges: int = 3

@export_group("Special Effects (Tylko dla CardType.INSTANT)")
@export var required_weapon_id: String = ""
## Używane TYLKO dla kart INSTANT (np. HealEffect) lub specjalnych perkow w przyszłości
@export var effects: Array[CardEffect] = []

func can_appear(player: Player) -> bool:
	if not player:
		return true

	var deck = player.get_deck_component()
	if not deck:
		return true

	# 1. Sprawdzenie maksymalnego poziomu dla kart statystyk
	if card_type == CardType.STAT and max_level > 0:
		if deck.get_card_level(self) >= max_level:
			return false

	# 2. Wymagana broń
	if not required_weapon_id.is_empty():
		var equipped_id = ""
		if deck.equipped_weapon:
			equipped_id = deck.equipped_weapon.weapon_id
		if required_weapon_id != equipped_id:
			return false

	# 3. Warunki efektów natychmiastowych (np. czy gracz potrzebuje leczenia)
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

	# Odpalamy efekty specjalne (np. leczenie)
	for effect in effects:
		if effect:
			effect.execute(player)
