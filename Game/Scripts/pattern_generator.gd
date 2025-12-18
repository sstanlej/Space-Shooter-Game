class_name PatternGenerator extends Node2D

func get_sinusoid(n: int, amp: int, gap: int) -> Array :
	var points : Array
	for i in range(n):
		var y : float = snapped(sin(i)*amp, 0.01)
		points.append([i*gap, y])
	return points
