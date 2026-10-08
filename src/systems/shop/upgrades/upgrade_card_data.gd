class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CardType { STAT, WEAPON, USABLE, INSTANT }
## Typ statystyki ulepszanej przez kartę STAT.
## Jednostki `stat_value_per_level` (zmiana na 1 poziom powyżej `base_level`):
enum StatType {
	NONE,
	## Płaska wartość obrażeń – np. 2.0 = +2 ATK
	DAMAGE,
	## Płaska prędkość ruchu w px/s – np. 10.0 = +10 px/s
	SPEED,
	## Mnożnik szybkości ostrzału – np. 0.15 = +15% (broń × (1 + suma))
	ATTACK_SPEED,
	## Liczba dodatkowych pocisków – np. 1.0 = +1 pocisk
	PROJECTILES,
	## Dodatkowe punkty życia – np. 1.0 = +1 HP
	MAX_HEALTH,
	## Mnożnik uniku – np. 0.1 = +10% (1.0 + suma)
	AGILITY
}
enum UsableType { NONE, SHIELD }

@export_group("Card Metadata")
@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.STAT

@export_group("Economy & Tier Settings")
@export var required_act: int = 1
@export var base_cost: int = 1
@export var cost_increase_per_level: int = 0

@export_group("Stat Settings")
@export var stat_type: StatType = StatType.NONE
## Wartość dodawana do statystyki za każdy poziom powyżej base_level (jednostki wg StatType)
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

func get_cost(player: Player) -> int:
	if not player:
		return base_cost
	var deck = player.get_deck_component()
	if not deck:
		return base_cost

	var current_level: int = deck.get_card_level(self)
	var additional_cost = maxi(0, current_level - base_level) * cost_increase_per_level
	return base_cost + additional_cost

func get_stat_bonus(current_level: int) -> float:
	return maxf(0.0, float(current_level - base_level)) * stat_value_per_level

func can_appear(player: Player, current_act: int = 1) -> bool:
	if current_act < required_act:
		return false

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

## Opis karty do wyświetlenia w UI.
## Dla kart STAT tekst jest generowany z stat_value_per_level,
## dzięki czemu nie rozjeżdża się z faktycznymi wartościami ulepszeń.
func get_display_description() -> String:
	if card_type == CardType.STAT and stat_type != StatType.NONE:
		return _get_stat_description()
	return description


func _get_stat_description() -> String:
	match stat_type:
		StatType.DAMAGE:
			return "+" + _fmt_value(stat_value_per_level) + " ATK"
		StatType.SPEED:
			return "+" + _fmt_value(stat_value_per_level) + " MV SPD"
		StatType.ATTACK_SPEED:
			return "+" + _fmt_value(stat_value_per_level * 100.0) + "% ATK SPD"
		StatType.PROJECTILES:
			return "+" + _fmt_value(stat_value_per_level) + " PROJECTILE"
		StatType.MAX_HEALTH:
			return "+" + _fmt_value(stat_value_per_level) + " MAX HP"
		StatType.AGILITY:
			return "+" + _fmt_value(stat_value_per_level * 100.0) + "% AGILITY"
	return description


## Formatuje liczbę bez zera po przecinku dla wartości całkowitych: 2.0 -> "2", 0.5 -> "0.5"
func _fmt_value(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return str(value)
