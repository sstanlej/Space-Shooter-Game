class_name CampaignManager extends Node

signal campaign_completed
signal act_changed(new_act_index: int, act_name: String)
signal location_changed(new_location: LocationData)
signal wave_advanced(global_wave: int)

@export_group("Campaign Setup")
@export var acts: Array[ActData] = []

var current_wave: int = 1
var current_act_index: int = 0
var current_location_index: int = 0
var current_wave_in_location_index: int = 0

func _ready() -> void:
	pass

func reset_campaign() -> void:
	current_wave = 1
	current_act_index = 0
	current_location_index = 0
	current_wave_in_location_index = 0

func get_current_act_data() -> ActData:
	if current_act_index >= 0 and current_act_index < acts.size():
		return acts[current_act_index]
	return null

func get_current_act() -> int:
	var act_data = get_current_act_data()
	if act_data:
		return act_data.act_index
	return current_act_index + 1

func get_effective_shop_act() -> int:
	# Jeśli jesteśmy na ostatniej fali bieżącego aktu (np. po zabiciu bossa),
	# sklep powinien oferować ulepszenia z kolejnego aktu!
	if is_current_wave_last_in_act():
		var next_act_index = current_act_index + 1
		if next_act_index < acts.size() and acts[next_act_index]:
			return acts[next_act_index].act_index
		return get_current_act() + 1
	
	return get_current_act()

func get_current_location() -> LocationData:
	var act = get_current_act_data()
	if act and current_location_index >= 0 and current_location_index < act.locations.size():
		return act.locations[current_location_index]
	return null

func get_current_wave_definition() -> WaveDefinition:
	var loc = get_current_location()
	if loc and current_wave_in_location_index >= 0 and current_wave_in_location_index < loc.waves.size():
		return loc.waves[current_wave_in_location_index]
	return null

func advance_wave() -> WaveDefinition:
	current_wave += 1
	current_wave_in_location_index += 1

	var loc = get_current_location()
	if loc and current_wave_in_location_index >= loc.waves.size():
		current_wave_in_location_index = 0
		current_location_index += 1

		var act = get_current_act_data()
		if act and current_location_index >= act.locations.size():
			current_location_index = 0
			current_act_index += 1
			if current_act_index < acts.size():
				var new_act = acts[current_act_index]
				act_changed.emit(new_act.act_index, new_act.act_name)
			else:
				campaign_completed.emit()
				return null

		var new_loc = get_current_location()
		if new_loc:
			location_changed.emit(new_loc)

	wave_advanced.emit(current_wave)
	return get_current_wave_definition()

func is_current_wave_last_in_act() -> bool:
	var act = get_current_act_data()
	var loc = get_current_location()
	if not act or not loc:
		return false
	var is_last_loc = (current_location_index == act.locations.size() - 1)
	var is_last_wave_in_loc = (current_wave_in_location_index == loc.waves.size() - 1)
	return is_last_loc and is_last_wave_in_loc

func get_upcoming_location() -> LocationData:
	var act = get_current_act_data()
	var loc = get_current_location()
	if not act or not loc:
		return null

	# Jeśli to nie jest ostatnia fala w obecnej lokacji, tło się nie zmienia
	var is_last_wave_in_loc = (current_wave_in_location_index >= loc.waves.size() - 1)
	if not is_last_wave_in_loc:
		return loc

	# Jeśli to ostatnia fala w lokacji, sprawdzamy następną lokację w tym akcie
	var next_loc_idx = current_location_index + 1
	if next_loc_idx < act.locations.size():
		return act.locations[next_loc_idx]

	# Jeśli to była ostatnia lokacja w akcie, sprawdzamy pierwszą lokację kolejnego aktu
	var next_act_idx = current_act_index + 1
	if next_act_idx < acts.size() and acts[next_act_idx]:
		var next_act = acts[next_act_idx]
		if not next_act.locations.is_empty():
			return next_act.locations[0]

	return loc
