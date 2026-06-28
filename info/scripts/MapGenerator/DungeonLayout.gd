class_name DungeonLayout
extends RefCounted

var rooms: Array[RoomData] = []
var grid_map: Dictionary = {}     # Vector2i -> RoomData

func register_room(room: RoomData) -> void:
	rooms.append(room)
	var top_left := room.grid_position + room.grid_offset  # offset applied here
	for x in range(room.grid_size.x):
		for y in range(room.grid_size.y):
			grid_map[top_left + Vector2i(x, y)] = room

# Returns true only if every cell in target_rect is free of rooms.
func is_space_free(target_rect: Rect2i) -> bool:
	for x in range(target_rect.size.x):
		for y in range(target_rect.size.y):
			var cell := target_rect.position + Vector2i(x, y)
			if grid_map.has(cell):
				return false
	return true
