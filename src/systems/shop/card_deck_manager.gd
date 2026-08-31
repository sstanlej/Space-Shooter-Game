class_name CardDeckManager extends Node

@export var available_cards: Array[UpgradeCardData] = []

var current_offer: Array[UpgradeCardData] = []

func has_available_upgrades(player: Player) -> bool:
	if not player:
		return false
	for card in available_cards:
		if card and card.can_appear(player):
			return true
	return false

func get_cards_for_shop(count: int, player: Player) -> Array[UpgradeCardData]:
	if current_offer.is_empty():
		roll_new_offer(count, player)
	return current_offer

func roll_new_offer(count: int, player: Player) -> Array[UpgradeCardData]:
	current_offer.clear()

	var valid_pool: Array[UpgradeCardData] = []
	for card in available_cards:
		if card and card.can_appear(player):
			valid_pool.append(card)

	valid_pool.shuffle()

	var draw_amount = mini(count, valid_pool.size())
	for i in range(draw_amount):
		current_offer.append(valid_pool[i])

	return current_offer

func reset_deck() -> void:
	current_offer.clear()