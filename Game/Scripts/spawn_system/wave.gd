class_name Wave extends Node2D

# TO DO
# Klasa Wave, ktora ma atrybut pattern oraz dokladny sklad przeciwnikow wraz z ich pozycjami
# skrypt spawner : spawn(wave)
# Fala 5: Pierwsze UFO, 10 HP - bo gracz jest juz wtedy wystarczajaco ulepszony i rozwala meteory bez problemu

var enemy_stats_config = {
	MeteorMovement: {"dmg": 1, "speed": 75, "hp": 3},
	UfoMovement: {"dmg": 2, "speed": 50, "hp": 50},
	DummySpawnPoint: {"dmg": 0, "speed": 0, "hp": 0}
}

var pattern: Pattern = Pattern.new()
var enemy_types: Array = []

func set_enemy_types(new_enemy_types: Array) -> void:
    enemy_types = new_enemy_types

func set_pattern(new_pattern: Pattern) -> void:
    pattern = new_pattern

func get_pattern() -> Pattern:
    return pattern

func get_size() -> int:
    return pattern.get_size()

func spawn(spawner_node: Spawner) -> void:
    var points: Array = pattern.get_pattern()
    for i in range(points.size()):
        var pos = Vector2(points[i][0], points[i][1])
        var type = enemy_types[i]
        var stats = enemy_stats_config.get(type, {"dmg": 0, "speed": 0, "hp": 0})
        spawner_node.spawn_enemy(pos, type, stats.dmg, stats.speed, stats.hp)