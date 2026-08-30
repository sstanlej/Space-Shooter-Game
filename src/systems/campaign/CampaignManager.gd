class_name CampaignManager extends Node

signal campaign_completed

@export_group("Campaign Setup")
@export var acts: Array[ActData] = []

@export_group("Difficulty & Budget Scaling")
@export var base_wave_budget: int = 10
@export var budget_growth_per_wave: int = 5

var _wave_cache: Dictionary = {}

func _ready() -> void:
	print_campaign_overview()

func reset_campaign() -> void:
	_wave_cache.clear()

# --- WAVE CONFIGURATION GENERATION ---

func get_wave_config(global_wave: int) -> WaveConfig:
	# Return cached configuration if already evaluated
	if _wave_cache.has(global_wave):
		return _wave_cache[global_wave]

	var config = WaveConfig.new()
	config.wave_number = global_wave
	config.wave_budget = base_wave_budget + (global_wave - 1) * budget_growth_per_wave

	if acts.is_empty():
		_wave_cache[global_wave] = config
		return config

	var accumulated_waves: int = 0

	for act in acts:
		if not act:
			continue

		var act_loc_waves = _calculate_act_location_waves(act)
		var act_total_waves = act_loc_waves + 1 # +1 reserved for the Act Boss wave

		if global_wave <= accumulated_waves + act_total_waves:
			var wave_in_act = global_wave - accumulated_waves
			config.act_index = act.act_index
			config.act_name = act.act_name

			# 1. Act Climax: Boss Battle
			if wave_in_act == act_total_waves:
				config.wave_type = WaveConfig.WaveType.BOSS
				config.is_act_final = true
				config.boss_scene = act.boss_scene
				config.boss_enemy_data = act.boss_enemy_data
				config.location = act.locations.back() if not act.locations.is_empty() else null
				_wave_cache[global_wave] = config
				return config

			# 2. Location Progression inside the Act
			var loc_info = _resolve_location_for_wave(act, wave_in_act)
			var current_loc: LocationData = loc_info["location"]
			var wave_in_this_loc: int = loc_info["wave_in_loc"]
			var total_waves_in_this_loc: int = loc_info["total_loc_waves"]

			config.location = current_loc

			# 3. Event Wave Check
			if current_loc and not current_loc.available_events.is_empty() and wave_in_this_loc == total_waves_in_this_loc:
				config.wave_type = WaveConfig.WaveType.EVENT
				config.event_id = current_loc.available_events.pick_random()
			else:
				config.wave_type = WaveConfig.WaveType.STANDARD

			_wave_cache[global_wave] = config
			return config

		accumulated_waves += act_total_waves

	# Endless Mode when all Acts are completed
	config = _build_endless_config(global_wave, accumulated_waves)
	_wave_cache[global_wave] = config
	return config

func _calculate_act_location_waves(act: ActData) -> int:
	var total = 0
	for loc in act.locations:
		if not loc:
			continue
		total += loc.custom_wave_count if loc.custom_wave_count > 0 else act.waves_per_location
	return total

func _resolve_location_for_wave(act: ActData, wave_in_act: int) -> Dictionary:
	var current_offset = 0

	for loc in act.locations:
		if not loc:
			continue

		var loc_waves = loc.custom_wave_count if loc.custom_wave_count > 0 else act.waves_per_location
		if wave_in_act <= current_offset + loc_waves:
			return {
				"location": loc,
				"wave_in_loc": wave_in_act - current_offset,
				"total_loc_waves": loc_waves
			}
		current_offset += loc_waves

	var fallback_loc = act.locations.back() if not act.locations.is_empty() else null
	return {
		"location": fallback_loc,
		"wave_in_loc": 1,
		"total_loc_waves": 1
	}

# --- STRUCTURED ENDLESS MODE ---

func _build_endless_config(global_wave: int, campaign_waves_total: int) -> WaveConfig:
	var config = WaveConfig.new()
	config.wave_number = global_wave
	config.wave_budget = base_wave_budget + (global_wave - 1) * budget_growth_per_wave
	config.act_name = "Endless Abyss"

	var all_locations = _get_all_campaign_locations()
	if all_locations.is_empty():
		config.wave_type = WaveConfig.WaveType.STANDARD
		return config

	var endless_wave_idx = global_wave - campaign_waves_total # Wave 1, 2, 3... in Endless

	# Boss battle every 10 waves in Endless
	if endless_wave_idx % 10 == 0:
		config.wave_type = WaveConfig.WaveType.BOSS
		config.is_act_final = false
		var last_act = acts.back()
		if last_act:
			config.boss_scene = last_act.boss_scene
			config.boss_enemy_data = last_act.boss_enemy_data
			config.location = last_act.locations.back() if not last_act.locations.is_empty() else all_locations[0]
		return config

	# Sectors of 3 waves per location in Endless
	var sector_size = 3
	var sector_index = int((endless_wave_idx - 1) / sector_size)
	var wave_in_sector = ((endless_wave_idx - 1) % sector_size) + 1

	var active_loc = all_locations[sector_index % all_locations.size()]
	config.location = active_loc

	# 3rd wave of a sector triggers an Event if available
	if wave_in_sector == sector_size and not active_loc.available_events.is_empty():
		config.wave_type = WaveConfig.WaveType.EVENT
		config.event_id = active_loc.available_events.pick_random()
	else:
		config.wave_type = WaveConfig.WaveType.STANDARD

	return config

func _get_all_campaign_locations() -> Array[LocationData]:
	var result: Array[LocationData] = []
	for act in acts:
		if not act:
			continue
		for loc in act.locations:
			if loc and not result.has(loc):
				result.append(loc)
	return result

# --- CONSOLE LOGGING ---

func print_campaign_overview() -> void:
	if acts.is_empty():
		print("[CampaignManager] No Acts configured in CampaignManager.")
		return

	print("\n========================= CAMPAIGN OVERVIEW =========================")
	var global_counter: int = 1

	for act in acts:
		if not act:
			continue

		var act_loc_waves = _calculate_act_location_waves(act)
		var act_total_waves = act_loc_waves + 1
		var start_wave = global_counter
		var end_wave = global_counter + act_total_waves - 1

		print(">>> Act %d: '%s' | Waves %d - %d (Total: %d waves)" % [
			act.act_index,
			act.act_name,
			start_wave,
			end_wave,
			act_total_waves
		])

		for w in range(1, act_total_waves + 1):
			var cfg = get_wave_config(global_counter)
			var loc_name = cfg.location.location_name if cfg.location else "None"
			var details = ""

			if cfg.wave_type == WaveConfig.WaveType.EVENT:
				details = " [Event: %s]" % cfg.event_id
			elif cfg.wave_type == WaveConfig.WaveType.BOSS:
				var boss_name = cfg.boss_enemy_data.enemy_name if cfg.boss_enemy_data else "Default Boss"
				details = " [Boss: %s]" % boss_name

			print("   Wave %2d (Act Wave %2d) | %-8s | Loc: %-22s%s | Budget: %d" % [
				global_counter,
				w,
				cfg.get_type_string(),
				loc_name,
				details,
				cfg.wave_budget
			])
			global_counter += 1

	print("=====================================================================\n")