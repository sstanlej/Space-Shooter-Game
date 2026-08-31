class_name ShopManager extends Node

signal offer_ready(cards: Array[UpgradeCardData])
signal shop_opened
signal shop_closed_by_manager
signal purchase_successful
signal purchase_failed
signal maxed_out

@export var progression_manager: ProgressionManager
@export var deck_manager: CardDeckManager

func has_available_upgrades(player: Player) -> bool:
	if deck_manager:
		return deck_manager.has_available_upgrades(player)
	return false

func open_shop(player: Player) -> void:
	shop_opened.emit()
	if not deck_manager:
		maxed_out.emit()
		return

	var cards = deck_manager.get_cards_for_shop(3, player)
	if cards.is_empty():
		maxed_out.emit()
	else:
		offer_ready.emit(cards)

func try_purchase_card(card: UpgradeCardData, player: Player) -> bool:
	if not progression_manager or not card:
		purchase_failed.emit()
		return false

	if progression_manager.get_upgrade_points() <= 0:
		purchase_failed.emit()
		return false

	if progression_manager.spend_upgrade_point():
		card.apply_to_player(player)
		purchase_successful.emit()

		if deck_manager:
			var next_cards = deck_manager.roll_new_offer(3, player)
			if next_cards.is_empty():
				maxed_out.emit()
			else:
				offer_ready.emit(next_cards)
		return true

	purchase_failed.emit()
	return false

func get_available_points() -> int:
	return progression_manager.get_upgrade_points() if progression_manager else 0