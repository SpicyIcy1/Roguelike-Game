@tool
extends TileMapLayer

var box_color: Color = Color.CORAL:
	set(value):
		box_color = value
		queue_redraw()


var line_thickness: float = 2.0:
	set(value):
		line_thickness = value
		queue_redraw() 

func _ready() -> void:
	
	if Engine.is_editor_hint():
		changed.connect(queue_redraw)

func _draw() -> void:
	if not Engine.is_editor_hint() or not tile_set:
		return
		
	var used_cells = get_used_cells()
	if used_cells.is_empty():
		return

	
	var min_x: int = used_cells[0].x
	var min_y: int = used_cells[0].y
	var max_x: int = used_cells[0].x
	var max_y: int = used_cells[0].y

	
	for cell in used_cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	
	# Top-left of the top-left tile
	var top_left = map_to_local(Vector2i(min_x, min_y)) - (Vector2(tile_set.tile_size) / 2)
	# Bottom-right of the bottom-right tile
	var bottom_right = map_to_local(Vector2i(max_x, max_y)) + (Vector2(tile_set.tile_size) / 2)
	
	var box_size = bottom_right - top_left
	var bounding_rect = Rect2(top_left, box_size)

	# Draw the rectangle outline
	draw_rect(bounding_rect, box_color, false, line_thickness)
