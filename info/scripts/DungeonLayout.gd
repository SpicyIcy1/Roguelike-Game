class_name DungeonLayout
extends RefCounted

var rooms: Array[RoomData] = []
var grid_map: Dictionary = {}     # Vector2i -> RoomData
var corridor_map: Dictionary = {} # Vector2i -> bool


func register_room(room: RoomData) -> void:
	rooms.append(room)
	var top_left := room.grid_position
	for x in range(room.grid_size.x):
		for y in range(room.grid_size.y):
			grid_map[top_left + Vector2i(x, y)] = room


func register_corridor(path_cells: Array[Vector2i]) -> void:
	for cell in path_cells:
		corridor_map[cell] = true


# Returns true only if every cell in target_rect is free of rooms AND corridors.
func is_space_free(target_rect: Rect2i) -> bool:
	for x in range(target_rect.size.x):
		for y in range(target_rect.size.y):
			var cell := target_rect.position + Vector2i(x, y)
			if grid_map.has(cell) or corridor_map.has(cell):
				return false
	return true


# Returns true if the proposed corridor path doesn't cut through any room wall.
# Corridors are allowed to cross other corridors, so corridor_map is ignored.
# The two door cells (first and last in path_cells) are excluded from the check.
func is_corridor_path_free(path_cells: Array[Vector2i], door_a: Vector2i, door_b: Vector2i) -> bool:
	for cell in path_cells:
		if cell == door_a or cell == door_b:
			continue
		if grid_map.has(cell):
			return false
	return true
