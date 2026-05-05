class_name Pattern extends Node2D

var slots: Array[PatternSlot] = []
var min_gap: int = 16
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

func get_pattern() -> Array:
	var points: Array = []
	for slot in slots:
		points += slot.get_points()
	return points

func get_size() -> int:
	return size