class_name UpgradeCardData extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CardType { STAT_BOOST, WEAPON_SWAP, WEAPON_SYNERGY, SPECIAL }

@export var card_id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D

@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.STAT_BOOST
@export var max_level: int = 5
var current_level: int = 0

@export var required_weapon_id: String = ""

@export_group("Stat Modifiers")
@export var flat_damage: float = 0.0
@export var percent_damage: float = 0.0
@export var percent_attack_speed: float = 0.0
@export var extra_projectiles: int = 0
@export var flat_movement_speed: float = 0.0

@export_group("Weapon Data")
@export var weapon_to_equip: WeaponData

func can_appear(equipped_weapon_id: String) -> bool:
	if current_level >= max_level:
		return false
	if not required_weapon_id.is_empty() and required_weapon_id != equipped_weapon_id:
		return false
	return true

func apply_to_player(player: Player) -> void:
	current_level += 1
	var stats = player.stats_component
	if not stats:
		return

	if card_type == CardType.WEAPON_SWAP and weapon_to_equip:
		player.attack_controller.equip_weapon(weapon_to_equip)

	if flat_damage != 0.0:
		stats.add_flat_damage(flat_damage)
	if percent_damage != 0.0:
		stats.add_damage_multiplier(percent_damage)
	if percent_attack_speed != 0.0:
		stats.add_attack_speed_multiplier(percent_attack_speed)
	if extra_projectiles != 0:
		stats.add_extra_projectiles(extra_projectiles)
	if flat_movement_speed != 0.0:
		stats.add_movement_speed(flat_movement_speed)