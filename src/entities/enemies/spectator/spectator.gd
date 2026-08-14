class_name Spectator extends Enemy

@export var eerie_sine_amplitude: float = 6.0 # Zakres unoszenia góra/dół (w pikselach)
@export var eerie_sine_speed: float = 2.5     # Szybkość falowania

var time_passed: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	# Eteryczna, lekka przezroczystość
	modulate.a = 0.85

func setup(enemy_data: EnemyData) -> void:
	super.setup(enemy_data)
	# Pobieramy pozycję bazową PO ustawieniu losowej pozycji przez Spawner:
	base_y = global_position.y

func do_movement(delta: float) -> void:
	time_passed += delta

	# Ruch w lewo z prędkością zdefiniowaną w EnemyData
	velocity.x = -move_speed
	
	# Płynne sinusoidalne unoszenie wokół wylosowanego Y
	global_position.y = base_y + sin(time_passed * eerie_sine_speed) * eerie_sine_amplitude

	move_and_slide()
