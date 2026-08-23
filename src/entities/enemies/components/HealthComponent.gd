class_name HealthComponent extends Node

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal healed(amount: int)
signal died

signal invincibility_started(duration: float)
signal invincibility_ended
signal shield_hit(remaining_charges: int)
signal shield_broken

@export_group("Health Settings")
@export var max_health: int = 100
var current_health: int

@export_group("I-Frames & Protection")
@export var enable_iframes_on_hit: bool = false
@export var default_iframe_duration: float = 1.0

var is_invincible: bool = false
var is_wave_invincible: bool = false
var shield_charges: int = 0

var iframe_timer: Timer

func _ready() -> void:
	current_health = max_health
	setup_iframe_timer()

func setup_iframe_timer() -> void:
	iframe_timer = Timer.new()
	iframe_timer.name = "IFrameTimer"
	iframe_timer.one_shot = true
	iframe_timer.timeout.connect(_on_iframe_timer_timeout)
	add_child(iframe_timer)

func set_max_health(new_max: int) -> void:
	max_health = new_max
	current_health = clampi(current_health, 1, max_health)
	health_changed.emit(current_health, max_health)

func set_health(new_health: int) -> void:
	max_health = new_health
	current_health = new_health
	health_changed.emit(current_health, max_health)

func heal(amount: int) -> void:
	if current_health >= max_health or amount <= 0:
		return

	current_health = min(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return current_health

# --- GŁÓWNA LOGIKA OBRAŻEŃ ---

func take_damage(amount: int) -> void:
	if current_health <= 0 or is_invincible or is_wave_invincible:
		return

	# Sprawdzenie tarczy
	if shield_charges > 0:
		var player = get_parent() as Player
		if player and player.get_deck_component():
			shield_charges = player.get_deck_component().consume_shield_charge()
		else:
			shield_charges -= 1

		shield_hit.emit(shield_charges)
		if shield_charges == 0:
			shield_broken.emit()

		start_invincibility(0.3)
		return

	current_health -= amount
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		died.emit()
	elif enable_iframes_on_hit:
		start_invincibility(default_iframe_duration)

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

func add_shield_charges(charges: int) -> void:
	shield_charges += charges

func _on_iframe_timer_timeout() -> void:
	if not is_wave_invincible:
		is_invincible = false
		invincibility_ended.emit()
