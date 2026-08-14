class_name CardDeckManager extends Node

@export var available_cards: Array[UpgradeCardData] = []

var current_offer: Array[UpgradeCardData] = []
var needs_reroll: bool = true

func mark_needs_reroll() -> void:
	needs_reroll = true

func clear_offer() -> void:
	current_offer.clear()
	needs_reroll = true

func get_cards_for_shop(count: int, player: Player) -> Array[UpgradeCardData]:
	if needs_reroll or current_offer.is_empty():
		roll_new_offer(count, player)
	return current_offer

func roll_new_offer(count: int, player: Player) -> Array[UpgradeCardData]:
	needs_reroll = false
	current_offer.clear()

	var valid_pool: Array[UpgradeCardData] = []
	for card in available_cards:
		if card and card.can_appear(player):
			valid_pool.append(card)

	valid_pool.shuffle()

	var draw_amount = min(count, valid_pool.size())
	for i in range(draw_amount):
		current_offer.append(valid_pool[i])

	return current_offer

func reset_deck() -> void:
	clear_offer()
	for card in available_cards:
		if card:
			card.current_level = 0