class_name PatternGenerator extends Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func get_sinusoid(n: int, amp: int, gap: int, offset: int) -> Array :
	var points : Array
	for i in range(n):
		var y : float = snapped(sin(i+offset)*amp, 0.01)
		points.append([i*gap, y])
	return points

func get_random_points(amount: int, start_x: int, min_gap: int, max_gap: int, min_y, max_y) -> Array:
	var points: Array
	var x_values: Array = []
	for i in range(amount): x_values.append(randi_range(min_gap, max_gap))
	x_values[0] += start_x
	for i in range(1, amount):
		x_values[i] += x_values[i-1]
	for i in range(amount):
		var y: int = rng.randi_range(min_y, max_y)
		var point: Array = [x_values[i], y]
		points.append(point)
	# print(points)
	return points

func get_straight_cluster(amount: int, gap: int, cluster_position: Vector2) -> Array:
	var points: Array = []
	points.append([cluster_position.x, cluster_position.y])
	var y: int = int(cluster_position.y) + gap
	for i in range(1, amount):
		points.append([cluster_position.x, y])
		y += gap
	print(points)
	return points

func get_enemy_list(meteors: int, ufos: int) -> Array:
	var enemy_list: Array
	var size: int = meteors + ufos
	for i in range(size):
		if ufos > 0:
			var r: int = rng.randi_range(0, 1)
			if r == 0:
				enemy_list.append(GameManager.Enemies.METEOR)
				meteors -= 1
			else:
				enemy_list.append(GameManager.Enemies.UFO)
				ufos -= 1
		else:
			enemy_list.append(GameManager.Enemies.METEOR)
			meteors -= 1
	return enemy_list
