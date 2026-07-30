class_name ZootEnemy extends ShootingEnemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super()
	animated_sprite.play("default")
