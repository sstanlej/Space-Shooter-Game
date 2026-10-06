class_name DrillEnemy extends Enemy

enum State { RISING, POSITIONED }

@export_group("Movement")
## Prędkość wspinania w górę (px/s)
@export var rise_speed: float = 15.0
## Wartość Y (globalnie), na której wiertło zatrzymuje ruch w górę
@export var stop_y: float = 67.5
## Dodatkowy margines pod ekranem, od którego wiertło zaczyna wychodzić
@export var spawn_margin: float = 10.0

@export_group("Shake")
## Amplituda drżenia sprite'a (hitbox się nie porusza)
@export var shake_amplitude: float = 1.0
## Co ile sekund losowana jest nowa pozycja drżenia
@export var shake_interval: float = 0.05

var state: State = State.RISING
var _shake_timer: float = 0.0
var _sprite_base_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	super._ready()
	if sprite:
		_sprite_base_pos = sprite.position


func setup(enemy_data: EnemyData) -> void:
	super.setup(enemy_data)
	state = State.RISING
	var vp: Vector2 = get_viewport_rect().size
	var sprite_size: Vector2 = _get_sprite_size()
	# Startujemy w całości pod ekranem, aby wiertło wysunęło się z dołu
	global_position.y = vp.y + sprite_size.y * 0.5 + spawn_margin
	# Losowany przez spawnera X kadrujemy tak, aby sprite mieścił się poziomo na ekranie
	var half_w: float = sprite_size.x * 0.5
	global_position.x = clampf(global_position.x, half_w, maxf(half_w, vp.x - half_w))


func _physics_process(delta: float) -> void:
	# Bazowa klasa sprawdza granice ekranu (wykrycie wejścia / ucieczki)
	super._physics_process(delta)
	if is_escaping:
		return
	if state == State.RISING:
		global_position.y -= rise_speed * delta
		if global_position.y <= stop_y:
			global_position.y = stop_y
			state = State.POSITIONED


func _process(delta: float) -> void:
	# Drżenie dotyczny wyłącznie sprite'a – hitbox pozostaje nieruchomy
	if not sprite:
		return
	_shake_timer -= delta
	if _shake_timer <= 0.0:
		_shake_timer = shake_interval
		sprite.position = _sprite_base_pos + Vector2(
			randf_range(-shake_amplitude, shake_amplitude),
			randf_range(-shake_amplitude, shake_amplitude)
		)


func _get_sprite_size() -> Vector2:
	if sprite and sprite.texture:
		return Vector2(
			absf(sprite.texture.get_size().x * sprite.scale.x),
			absf(sprite.texture.get_size().y * sprite.scale.y)
		)
	return Vector2(32.0, 128.0)
