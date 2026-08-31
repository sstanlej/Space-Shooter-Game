class_name PlayerHealthComponent extends HealthComponent

signal invincibility_started(duration: float)
signal invincibility_ended
signal shield_hit(remaining_charges: int)
signal shield_broken

@export_group("Shield Protection")
var shield_charges: int = 0

@export_group("I-Frames Settings")
@export var enable_iframes_on_hit: bool = true
@export var default_iframe_duration: float = 1.0

var is_invincible: bool = false
var is_wave_invincible: bool = false
var iframe_timer: Timer

func _ready() -> void:
	super._ready()
	setup_iframe_timer()

func setup_iframe_timer() -> void:
	iframe_timer = Timer.new()
	iframe_timer.name = "IFrameTimer"
	iframe_timer.one_shot = true
	iframe_timer.timeout.connect(_on_iframe_timer_timeout)
	add_child(iframe_timer)

func take_damage(amount: int) -> void:
	if current_health <= 0 or is_invincible or is_wave_invincible or amount <= 0:
		return

	# 1. Shield absorbs the hit completely
	if shield_charges > 0:
		shield_charges -= 1
		shield_hit.emit(shield_charges)
		if shield_charges == 0:
			shield_broken.emit()
		start_invincibility(0.3)
		return

	# 2. If no shield, process base health damage
	super.take_damage(amount)

	# 3. Trigger I-Frames if player survived the hit
	if current_health > 0 and enable_iframes_on_hit:
		start_invincibility(default_iframe_duration)

func add_shield_charges(charges: int) -> void:
	shield_charges += charges
	shield_hit.emit(shield_charges)

func set_shield_charges(charges: int) -> void:
	shield_charges = max(0, charges)
	shield_hit.emit(shield_charges)

func start_invincibility(duration: float) -> void:
	is_invincible = true
	invincibility_started.emit(duration)
	if iframe_timer:
		iframe_timer.start(duration)

func set_wave_invincibility(active: bool) -> void:
	is_wave_invincible = active
	if active:
		invincibility_started.emit(-1.0)
	else:
		is_invincible = false
		invincibility_ended.emit()

func _on_iframe_timer_timeout() -> void:
	if not is_wave_invincible:
		is_invincible = false
		invincibility_ended.emit()