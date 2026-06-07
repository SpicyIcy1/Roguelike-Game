class_name RoomData
extends Resource

enum RoomType { START, STANDARD, SHOP, TREASURE, BOSS }

var room_file_name: String = ""
var grid_position: Vector2i = Vector2i.ZERO
var grid_size: Vector2i = Vector2i.ZERO
var available_exits: Dictionary = {}   # { "North": Vector2i, ... }
var connected_rooms: Dictionary = {}   # { "North": RoomData|null, ... }
var room_type: RoomType = RoomType.STANDARD
