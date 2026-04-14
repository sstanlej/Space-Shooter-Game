class_name Pattern extends Node2D

var size: int
var points: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_list(point_list: Array) -> void:
	points = point_list
	size = points.size()

func get_pattern() -> Array:
	return points

func get_size():
	return points.size()

func add_list(point_list: Array) -> void:
	points += point_list
	size = points.size()

func add_pattern(pattern: Pattern) -> void:
	points += pattern.get_pattern()
	size = points.size()

func clusterify(x_index: int, amount: int, gap_y: int) -> void:
	var cluster_position: Array = points[x_index]
	points.remove_at(x_index)
	self.add_cluster(amount, 0, gap_y, cluster_position)

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

# func get_straight_cluster(amount: int, gap: int, cluster_position: Vector2) -> Array:
#     var point_list: Array = []
#     point_list.append([cluster_position.x, cluster_position.y])
#     var y: int = int(cluster_position.y) + gap
#     for i in range(1, amount):
#         point_list.append([cluster_position.x, y])
#         y += gap
#     return points
