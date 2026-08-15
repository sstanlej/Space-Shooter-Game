class_name ZootEnemy extends OscillatingEnemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	animated_sprite.play("default")
