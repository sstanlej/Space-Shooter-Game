class_name CardDeckManager extends Node

@export var available_cards: Array[UpgradeCardData] = []

func get_random_cards(count: int, player: Player) -> Array[UpgradeCardData]:
	var current_weapon_id = ""
	if player and player.attack_controller and player.attack_controller.equipped_weapon:
		current_weapon_id = player.attack_controller.equipped_weapon.weapon_id

	var valid_pool: Array[UpgradeCardData] = []
	for card in available_cards:
		if card and card.can_appear(current_weapon_id):
			valid_pool.append(card)

	valid_pool.shuffle()

	var drawn_cards: Array[UpgradeCardData] = []
	var draw_amount = min(count, valid_pool.size())
	for i in range(draw_amount):
		drawn_cards.append(valid_pool[i])

	return drawn_cards