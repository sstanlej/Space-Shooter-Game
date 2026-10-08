class_name PlayerProjectile extends Projectile

## Bazowe przebicie pocisku – zmień tutaj, żeby zmienić domyślną wartość (strzały i UI czytają z tego miejsca)
const BASE_PIERCING: int = 0

var piercing_amount: int = BASE_PIERCING
var number_of_pierces: int = 0

func on_hit() -> void:
	if number_of_pierces < piercing_amount:
		number_of_pierces += 1
	else:
		queue_free()
