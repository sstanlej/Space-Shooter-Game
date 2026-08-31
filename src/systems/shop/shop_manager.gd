class_name ShopManager extends Node

signal offer_ready(cards: Array[UpgradeCardData])
signal shop_opened
signal purchase_successful
signal purchase_failed
signal maxed_out

@export var progression_manager: ProgressionManager
@export var deck_manager: CardDeckManager
@export var campaign_manager: CampaignManager

func get_current_act() -> int:
	if campaign_manager:
		if campaign_manager.has_method("get_effective_shop_act"):
			return campaign_manager.get_effective_shop_act(true)
		return campaign_manager.current_act_index
	return 1
func has_available_upgrades(player: Player, current_act: int = -1) -> bool:
	if current_act < 0:
		current_act = get_current_act()
	if deck_manager:
		return deck_manager.has_available_upgrades(player, current_act)
	return false

func open_shop(player: Player) -> void:
	shop_opened.emit()
	if not deck_manager:
		maxed_out.emit()
		return

	var act = get_current_act()
	var cards = deck_manager.get_cards_for_shop(3, player, act)
	if cards.is_empty():
		maxed_out.emit()
	else:
		offer_ready.emit(cards)

func try_purchase_card(card: UpgradeCardData, player: Player) -> bool:
	if not progression_manager or not card:
		purchase_failed.emit()
		return false

	var cost: int = card.get_cost(player)
	if progression_manager.get_upgrade_points() < cost:
		purchase_failed.emit()
		return false

	if progression_manager.spend_upgrade_points(cost):
		card.apply_to_player(player)
		purchase_successful.emit()

		if deck_manager:
			var act = get_current_act()
			var next_cards = deck_manager.roll_new_offer(3, player, act)
			if next_cards.is_empty():
				maxed_out.emit()
			else:
				offer_ready.emit(next_cards)
		return true

	purchase_failed.emit()
	return false

func get_available_points() -> int:
	return progression_manager.get_upgrade_points() if progression_manager else 0