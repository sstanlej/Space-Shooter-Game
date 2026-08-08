class_name Wave extends Node2D

var pattern: Pattern = Pattern.new()
# Zamiast typów GDScript, ta tablica trzyma teraz obiekty EnemyData!
var enemy_datas: Array[EnemyData] = []

func set_enemy_datas(new_enemy_datas: Array[EnemyData]) -> void:
	enemy_datas = new_enemy_datas

func set_pattern(new_pattern: Pattern) -> void:
	pattern = new_pattern

func get_pattern() -> Pattern:
	return pattern

func get_size() -> int:
	return pattern.get_size()

# Funkcja spawn tworzy wrogów i przekazuje im ich zasób EnemyData
func spawn(spawner_node: Spawner) -> void:
	var points: Array = pattern.get_pattern()
	for i in range(points.size()):
		var pos = Vector2(points[i][0], points[i][1])
		var data = enemy_datas[i]
		spawner_node.spawn_enemy(pos, data)