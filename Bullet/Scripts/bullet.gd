class_name Bullet extends Area2D

@export var move_speed : float = 200
@export var attack_damage : float = 1
var direction = Vector2.RIGHT
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	position += move_speed * direction * delta


func _on_area_entered(area: Area2D) -> void:
	if !area.find_parent("Player"):
		if area.has_method("damage"):
			area.damage(attack_damage)
			queue_free()
