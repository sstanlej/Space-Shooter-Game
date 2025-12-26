extends AttackControlerBooster

var current_cooldown: float
var original_cooldown: float

func affect_player() -> void:
	if !player:
		return
	attack_controler = get_attack_controler()
	if(!attack_controler):
		return
	current_cooldown = attack_controler.get_cooldown()
	original_cooldown = attack_controler.get_original_cooldown()
	attack_controler.set_cooldown(current_cooldown/level)
	$DurationTime.start()

func revert_changes() -> void:
	if !attack_controler:
		return
	attack_controler.set_cooldown(original_cooldown)
	queue_free()
