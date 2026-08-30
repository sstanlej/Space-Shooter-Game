class_name WaveConfig extends RefCounted

enum WaveType {
	STANDARD,
	EVENT,
	BOSS
}

var wave_number: int = 1
var wave_type: WaveType = WaveType.STANDARD
var wave_budget: int = 10

var location: LocationData = null
var event_id: String = ""

var boss_scene: PackedScene = null
var boss_enemy_data: EnemyData = null

var act_index: int = 1
var act_name: String = ""
var is_act_final: bool = false

# --- STRING HELPERS ---

static func get_type_name(type: WaveType) -> String:
	match type:
		WaveType.STANDARD:
			return "STANDARD"
		WaveType.EVENT:
			return "EVENT"
		WaveType.BOSS:
			return "BOSS"
	return "UNKNOWN"

func get_type_string() -> String:
	return get_type_name(wave_type)