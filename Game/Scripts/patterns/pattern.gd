class_name Pattern extends Node2D

var size: int
var points: Array = []
var x_indexes: Array = []
var y_indexes: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_list(point_list: Array) -> void:
	points = point_list
	update_arrays()

func update_arrays() -> void:
	size = points.size()
	points.sort_custom(func(a, b): return a[0] < b[0]) # chuj to ty twoja stara
	x_indexes = []
	y_indexes = []
	for i in size:
		var x_index: int = points[i][0]
		if x_index not in x_indexes:
			x_indexes.append(x_index)
		y_indexes.append(points[i][1])

func get_x_indexes() -> Array:
	return x_indexes

func get_y_indexes() -> Array:
	return y_indexes

func get_pattern() -> Array:
	return points

func get_size():
	return points.size()

func add_list(point_list: Array) -> void:
	points += point_list
	update_arrays()

func add_pattern(pattern: Pattern) -> void:
	points += pattern.get_pattern()
	update_arrays()

func clusterify(x_index: int, amount: int, gap_y: int) -> void:
	var cluster_position: Array = points[x_index]
	points.remove_at(x_index)
	self.add_cluster(amount, 0, gap_y, cluster_position)
	update_arrays()

func add_cluster(cluster_size: int, gap_x: int, gap_y, cluster_start: Array) -> void:
	var point_list: Array = []
	if cluster_start == []:
		cluster_start = [points[-1][0] + gap_x, 15]
	point_list.append(cluster_start)
	var y: int = cluster_start[1] + gap_y
	for i in range(1, cluster_size):
		point_list.append([cluster_start[0], y])
		y += gap_y
	points += point_list
	update_arrays()


func add_random_points(amount: int, start_x: int, min_gap: int, max_gap: int, min_y, max_y) -> void:
	var point_list: Array
	var x_values: Array = []
	for i in range(amount): x_values.append(rng.randi_range(min_gap, max_gap))
	x_values[0] = x_values[0] / 2 + start_x
	for i in range(1, amount):
		x_values[i] += x_values[i-1]
	for i in range(amount):
		var y: int = rng.randi_range(min_y, max_y)
		var point: Array = [x_values[i], y]
		point_list.append(point)
	points += point_list
	update_arrays()
