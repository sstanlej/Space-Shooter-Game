class_name PatternGenerator extends Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func get_sinusoid(n: int, amp: int, gap: int, offset: int) -> Array :
	var points : Array
	for i in range(n):
		var y : float = snapped(sin(i+offset)*amp, 0.01)
		points.append([i*gap, y])
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
