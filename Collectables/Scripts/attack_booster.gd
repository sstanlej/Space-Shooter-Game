extends AttackControlerBooster

var original_damage: float
var current_damage: float

func affect_player() -> void:
	if !player:
		return
	attack_controler = get_attack_controler()
	if(!attack_controler):
		return
	original_damage = attack_controler.get_original_damage()
	current_damage = attack_controler.get_damage()
	attack_controler.set_damage(current_damage * level)
	attack_controler.boosted = true
	$DurationTime.start()

func revert_changes() -> void:
	if !attack_controler:
		return
	attack_controler.set_damage(original_damage)
	attack_controler.boosted = false
	queue_free()
