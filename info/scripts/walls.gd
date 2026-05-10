extends TileMapLayer

var starting_room_size = Vector2i(10,10)

func _ready() -> void:
	create_square_room(Vector2i(0,0), Vector2i(32,18))
	#for x in starting_room_size.x:
		#for y in starting_room_size.y:
			#set_cell(Vector2i(x,y),0, Vector2i(0,0))
	

func create_square_room(start_pos: Vector2i, room_size: Vector2i):
	for x in range(room_size.x):
		for y in range(room_size.y):
			# Check if we are on any of the four edges
			var is_left_edge = (x == 0)
			var is_right_edge = (x == room_size.x - 1)
			var is_top_edge = (y == 0)
			var is_bottom_edge = (y == room_size.y - 1)
			
			if is_left_edge or is_right_edge or is_top_edge or is_bottom_edge:
				# Place the tile at the start_pos offset
				set_cell(start_pos + Vector2i(x, y), 0, Vector2i(0, 0))
