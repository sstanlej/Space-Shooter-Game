class_name Pattern extends Node2D

var slots: Array[PatternSlot] = []
var min_gap: int = 20
var size: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func generate_random_base(pattern_size: int, start_x: int, min_x_gap: int, max_x_gap: int) -> void:
	var x_values: Array = []
	for i in range(pattern_size):
		x_values.append(rng.randi_range(min_x_gap, max_x_gap))
	x_values[0] = x_values[0] / 2 + start_x
	for i in range(1, pattern_size):
		x_values[i] += x_values[i-1]
	for i in range(pattern_size):
		var y: int = rng.randi_range(Spawner.min_y, Spawner.max_y)
		var slot = PatternSlot.new(Vector2(x_values[i], y))
		slots.append(slot)
	size = pattern_size

func make_vertical_cluster(slot_index: int, cluster_size: int, gap_y: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_vertical_cluster(cluster_size, gap_y)
	size = get_pattern().size()

func make_horizontal_cluster(slot_index: int, cluster_size: int, gap_x: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_horizontal_cluster(cluster_size, gap_x, is_position_safe)
	size = get_pattern().size()

func make_key_cluster(slot_index: int, cluster_size: int, gap_x: int, gap_y: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_key_cluster(cluster_size, gap_x, gap_y, is_position_safe)
	size = get_pattern().size()

func make_block_cluster(slot_index: int, cluster_size_x: int, cluster_size_y: int, gap_x: int, gap_y: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_block_cluster(cluster_size_x, cluster_size_y, gap_x, gap_y, is_position_safe)
	size = get_pattern().size()

func make_rising_cluster(slot_index: int, cluster_size: int, gap_x: int, gap_y: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_rising_cluster(cluster_size, gap_x, gap_y, is_position_safe)
	size = get_pattern().size()

func make_falling_cluster(slot_index: int, cluster_size: int, gap_x: int, gap_y: int) -> void:
	if slot_index >= 0 and slot_index < slots.size() and slots[slot_index].type == "single":
		slots[slot_index].make_falling_cluster(cluster_size, gap_x, gap_y, is_position_safe)
	size = get_pattern().size()

func make_cluster(slot_index: int, cluster_type: String, params: Dictionary) -> void:
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index].type != "single":
		return
	var slot = slots[slot_index]
	match cluster_type:
		"vertical":
			slot.make_vertical_cluster(params.get("size", 3), params.get("gap_y", 20))
		"horizontal":
			slot.make_horizontal_cluster(params.get("size", 3), params.get("gap_x", 20), is_position_safe)
		"block":
			slot.make_block_cluster(params.get("size_x", 2), params.get("size_y", 2), params.get("gap_x", 20), params.get("gap_y", 20), is_position_safe)
		"rising":
			slot.make_rising_cluster(params.get("size", 3), params.get("gap_x", 20), params.get("gap_y", 10), is_position_safe)
		"falling":
			slot.make_falling_cluster(params.get("size", 3), params.get("gap_x", 20), params.get("gap_y", 10), is_position_safe)
		"key":
			slot.make_key_cluster(params.get("size", 3), params.get("gap_x", 20), params.get("gap_y", 10), is_position_safe)
	size = get_pattern().size()

func is_position_safe(pos: Vector2) -> bool:
	for slot in slots:
		for point in slot.get_points():
			if pos.distance_squared_to(point) < min_gap * min_gap:
				return false
	return true

func get_pattern() -> Array:
	var points: Array = []
	for slot in slots:
		points += slot.get_points()
	return points

func get_size() -> int:
	return size
