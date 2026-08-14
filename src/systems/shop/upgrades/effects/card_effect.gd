class_name CardEffect extends Resource

# Domyślnie efekt zawsze może się pojawić
func can_appear(_player: Player) -> bool:
	return true

func execute(_player: Player) -> void:
	pass