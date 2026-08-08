class_name PlayerProjectile extends Projectile

func on_hit() -> void:
	# Play a different sound
	queue_free()
