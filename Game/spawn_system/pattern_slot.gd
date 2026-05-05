class_name PatternSlot extends Node2D

var base_position: Vector2
var points: Array[Vector2] = []
var type: String # "single", "vertical_cluster"

func _init(pos: Vector2) -> void:
    base_position = pos
    points.append(base_position)
    type = "single"

func make_vertical_cluster(cluster_size: int, gap_y: int) -> void:
    type = "vertical_cluster"
    points = []
    for i in range(-cluster_size/2, cluster_size/2 + cluster_size % 2):
        var new_point = Vector2(base_position.x, base_position.y + i * gap_y)
        if new_point.y > Spawner.max_y or new_point.y < Spawner.min_y:
            print("Cluster point %s crossed limit" % new_point)
            continue
        points.append(new_point)

func get_points() -> Array[Vector2]:
    return points