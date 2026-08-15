class_name GhostProjectile extends Projectile

@export var lifetime: float = 3.0

func _ready() -> void:
	# Pocisk widmo nie ma kolizji fizycznej
	collision_layer = 0
	collision_mask = 0
	
	# Automatyczne czyszczenie po czasie
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta