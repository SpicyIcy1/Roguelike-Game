class_name RoomData
extends Resource

var room_file_name: String = ""
var scene_path: String = ""      # vollständiger für die spezialen Räume außerhalb des room folders (bisher nur der Boss raum)
var grid_position: Vector2i = Vector2i.ZERO
var grid_offset: Vector2i = Vector2i.ZERO  # used_rect.position from TileMapLayer
var grid_size: Vector2i = Vector2i.ZERO
var available_exits: Dictionary = {}   # { "North": Vector2i, ... }
var connected_rooms: Dictionary = {}   # { "North": RoomData|null, ... }
