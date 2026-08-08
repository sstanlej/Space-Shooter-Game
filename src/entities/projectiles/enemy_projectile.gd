class_name EnemyProjectile extends Projectile

func on_hit() -> void:
    GlobalAudio.play_crash()
    queue_free()