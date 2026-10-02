class_name PlayerProjectile extends Projectile

var piercing_amount: int = 1
var number_of_pierces: int = 0

func on_hit() -> void:
	if number_of_pierces < piercing_amount:
		number_of_pierces += 1
	else:
		queue_free()
