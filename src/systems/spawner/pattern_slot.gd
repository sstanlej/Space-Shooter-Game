class_name PatternSlot

var base_position: Vector2
var points: Array[Vector2] = []
var type: String # "single", "vertical_cluster", "horizontal_cluster"

# func _init(pos: Vector2) -> void:
#     base_position = pos
#     points.append(base_position)
#     type = "single"

# func make_vertical_cluster(cluster_size: int, gap_y: int) -> void:
#     type = "vertical_cluster"
#     points = []
#     for i in range(-cluster_size/2, cluster_size/2 + cluster_size % 2):
#         var new_point = Vector2(base_position.x, base_position.y + i * gap_y)
#         if new_point.y > Spawner.max_y or new_point.y < Spawner.min_y:
#             print("Cluster point %s crossed limit" % new_point)
#             continue
#         points.append(new_point)

# func make_horizontal_cluster(cluster_size: int, gap_x: int, validator: Callable) -> void:
#     type = "horizontal_cluster"
#     points = []
#     for i in range(cluster_size):
#         var new_point = Vector2(base_position.x + i * gap_x, base_position.y)
#         if validator.call(new_point):
#             points.append(new_point)
#         else:
#             print("Cluster point %s is too close to another point, skipping" % new_point)

# func make_key_cluster(cluster_size: int, gap_x: int, gap_y: int, validator: Callable) -> void:
#     type = "key_cluster"
#     points = [Vector2(base_position.x, base_position.y)]
#     for i in range(1, cluster_size / 2 + 1):
#         var new_point1 = Vector2(base_position.x + i * gap_x, base_position.y + i * gap_y)
#         var new_point2 = Vector2(base_position.x + i * gap_x, base_position.y - i * gap_y)
#         if new_point1.y > Spawner.max_y or new_point1.y < Spawner.min_y:
#             print("Cluster point %s crossed limit" % new_point1)
#             continue
#         if new_point2.y > Spawner.max_y or new_point2.y < Spawner.min_y:
#             print("Cluster point %s crossed limit" % new_point2)
#             continue
#         if validator.call(new_point1):
#             points.append(new_point1)
#         else:
#             print("Cluster point %s is too close to another point, skipping" % new_point1)
#         if validator.call(new_point2):
#             points.append(new_point2)
#         else:
#             print("Cluster point %s is too close to another point, skipping" % new_point2)

# func make_block_cluster(cluster_size_x: int, cluster_size_y: int, gap_x: int, gap_y: int, validator: Callable) -> void:
#     type = "block_cluster"
#     points = []
#     for i in range(cluster_size_x):
#         for j in range(cluster_size_y):
#             var new_point = Vector2(base_position.x + i * gap_x, base_position.y - j * gap_y)
#             if new_point.y > Spawner.max_y or new_point.y < Spawner.min_y:
#                 print("Cluster point %s crossed limit" % new_point)
#                 continue
#             if validator.call(new_point):
#                 points.append(new_point)
#             else:
#                 print("Cluster point %s is too close to another point, skipping" % new_point)

# func make_rising_cluster(cluster_size: int, gap_x: int, gap_y: int, validator: Callable) -> void:
#     type = "rising_cluster"
#     points = []
#     for i in range(-cluster_size/2, cluster_size/2 + cluster_size % 2):
#         var new_point = Vector2(base_position.x + i * gap_x, base_position.y - i * gap_y)
#         if new_point.y > Spawner.max_y or new_point.y < Spawner.min_y:
#             print("Cluster point %s crossed limit" % new_point)
#             continue
#         if validator.call(new_point):
#             points.append(new_point)
#         else:
#             print("Cluster point %s is too close to another point, skipping" % new_point)

# func make_falling_cluster(cluster_size: int, gap_x: int, gap_y: int, validator: Callable) -> void:
#     type = "falling_cluster"
#     points = []
#     for i in range(-cluster_size/2, cluster_size/2 + cluster_size % 2):
#         var new_point = Vector2(base_position.x + i * gap_x, base_position.y + i * gap_y)
#         if new_point.y > Spawner.max_y or new_point.y < Spawner.min_y:
#             print("Cluster point %s crossed limit" % new_point)
#             continue
#         if validator.call(new_point):
#             points.append(new_point)
#         else:
#             print("Cluster point %s is too close to another point, skipping" % new_point)

# func get_points() -> Array[Vector2]:
#     return points