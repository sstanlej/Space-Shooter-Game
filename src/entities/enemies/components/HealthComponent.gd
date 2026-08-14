class_name HealthComponent extends Node

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal healed(amount: int)
signal died

# Sygnały dla tarcz i nietykalności
signal invincibility_started(duration: float)
signal invincibility_ended
signal shield_hit(remaining_charges: int)
signal shield_broken

@export_group("Health Settings")
@export var max_health: int = 10
var current_health: int

@export_group("I-Frames & Protection")
@export var enable_iframes_on_hit: bool = false  # Zaznacz TRUE tylko u gracza
@export var default_iframe_duration: float = 1.0 # Czas nietykalności po oberwaniu w sekundach

# Stany ochronne
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
	print("[HealthComponent] Healed by ", amount, ". Current HP: ", current_health, "/", max_health)

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return current_health

# --- GŁÓWNA LOGIKA OTRZYMYWANIA OBRAŻEŃ (ZGODNA ZE STARYM KODEM) ---

func take_damage(amount: int) -> void:
	# 1. Zabezpieczenie przed obrażeniami w trakcie nietykalności lub śmierci
	if current_health <= 0 or is_invincible or is_wave_invincible:
		return

	# 2. Sprawdzenie tarczy absorbującej uderzenia
	if shield_charges > 0:
		shield_charges -= 1
		shield_hit.emit(shield_charges)
		if shield_charges == 0:
			shield_broken.emit()
		
		# Krótki I-frame (0.3s) po zbiciu ładunku tarczy, by pociski nie skasowały dwóch ładunków w tej samej klatce
		start_invincibility(0.3)
		return

	# 3. Właściwe odjęcie HP i emisja sygnałów
	current_health -= amount
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		died.emit()
	elif enable_iframes_on_hit:
		# Odpalamy pełną nietykalność jeśli włączona (np. u gracza)
		start_invincibility(default_iframe_duration)

# --- INTERFEJS DLA KART I ULEPSZEŃ (NOWOŚCI) ---

func start_invincibility(duration: float) -> void:
	is_invincible = true
	invincibility_started.emit(duration)
	if iframe_timer:
		iframe_timer.start(duration)

func set_wave_invincibility(active: bool) -> void:
	is_wave_invincible = active
	if active:
		# Przesyłamy ujemny czas, by UI/skrypty wiedziały, że to nietykalność stała (aż do wyłączenia)
		invincibility_started.emit(-1.0) 
	else:
		is_invincible = false # Zdejmujemy ewentualne resztki zwykłej nietykalności
		invincibility_ended.emit()

func add_shield_charges(charges: int) -> void:
	shield_charges += charges

func _on_iframe_timer_timeout() -> void:
	if not is_wave_invincible:
		is_invincible = false
		invincibility_ended.emit()
