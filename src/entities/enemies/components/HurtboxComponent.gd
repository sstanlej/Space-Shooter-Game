class_name HurtboxComponent extends Area2D

@export var health_component: HealthComponent
@export var contact_damage: float = 0.0

func _ready() -> void:
	if not health_component and owner:
		health_component = owner.get_node_or_null("HealthComponent")
	area_entered.connect(_on_area_entered)

func damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

func _on_area_entered(area: Area2D) -> void:
	if contact_damage > 0.0 and area.has_method("damage"):
		area.damage(int(contact_damage))
		if typeof(GlobalAudio) != TYPE_NIL and GlobalAudio.has_method("play_crash"):
			GlobalAudio.play_crash()
		if owner and owner.has_method("die_by_collision"):
			owner.die_by_collision()