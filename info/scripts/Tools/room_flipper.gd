@tool
extends EditorScript

const SOURCE_SCENE_PATH := "res://scenes/rooms/Room_9.tscn"
const TARGET_SCENE_PATH := "res://scenes/rooms/Room_9b.tscn"
const TILE_SIZE := 16

func _run() -> void:
	if not FileAccess.file_exists(SOURCE_SCENE_PATH):
		print("Error: Source scene not found: ", SOURCE_SCENE_PATH)
		return

	var original_scene: PackedScene = load(SOURCE_SCENE_PATH)
	if not original_scene or not original_scene.can_instantiate():
		print("Error: Could not load source scene.")
		return

	var instance: Node = original_scene.instantiate()
	var tile_map: TileMapLayer = _find_tilemap_layer(instance)
	if not tile_map:
		print("Error: No TileMapLayer found.")
		instance.free()
		return

	var used_rect := tile_map.get_used_rect()
	var offset_x  := used_rect.position.x
	var size_x    := used_rect.size.x
	var axis_px   := ((offset_x + offset_x + size_x) * TILE_SIZE) / 2.0

	# 1. Mirror tile cells
	var cell_data: Array[Dictionary] = []
	for cell in tile_map.get_used_cells():
		cell_data.append({
			"cell":         cell,
			"source_id":    tile_map.get_cell_source_id(cell),
			"atlas_coords": tile_map.get_cell_atlas_coords(cell),
			"alt_tile":     tile_map.get_cell_alternative_tile(cell),
		})

	tile_map.clear()
	for data in cell_data:
		var old_cell: Vector2i = data["cell"]
		var new_x   := offset_x + (offset_x + size_x - 1 - old_cell.x)
		var new_alt : int = data["alt_tile"] ^ TileSetAtlasSource.TRANSFORM_FLIP_H
		tile_map.set_cell(Vector2i(new_x, old_cell.y), data["source_id"], data["atlas_coords"], new_alt)

	# 2. Mirror positions and scales of regular elements (ignoring exits)
	for child in instance.get_children():
		_mirror_recursive(child, axis_px, true)
		
	# 3. Explicitly handle exits anywhere in the tree
	_handle_exits(instance, axis_px)

	# 4. Save scene
	var packed := PackedScene.new()
	if packed.pack(instance) == OK and ResourceSaver.save(packed, TARGET_SCENE_PATH) == OK:
		print("Successfully saved mirrored room to: ", TARGET_SCENE_PATH)
	else:
		print("Error saving/packing scene.")

	instance.free()

func _mirror_recursive(node: Node, axis_px: float, is_direct_child: bool) -> void:
	# Skip processing if this is an exit node (handled separately)
	if node.name == "Exit_W" or node.name == "Exit_E":
		return

	if node is Node2D and not node is TileMapLayer:
		if is_direct_child:
			node.position.x = 2.0 * axis_px - node.position.x
			node.scale.x *= -1.0
			
		elif node is Marker2D and node.get_parent().name.begins_with("EnemySpawnZone"):
			node.position.x = -node.position.x

	for child in node.get_children():
		_mirror_recursive(child, axis_px, false)

# Dedicated function to hunt down and flip/rename exits safely
func _handle_exits(node: Node, axis_px: float) -> void:
	var exit_swap := {"Exit_W": "Exit_E", "Exit_E": "Exit_W"}
	
	if node.name in exit_swap:
		if node is Node2D:
			node.position.x = 2.0 * axis_px - node.position.x
			node.scale.x *= -1.0
		
		# Rename them last so we don't mess up the dictionary lookup loop
		node.name = exit_swap[node.name]
		return # Found it, no need to look at its children

	for child in node.get_children():
		_handle_exits(child, axis_px)

func _find_tilemap_layer(root: Node) -> TileMapLayer:
	if root is TileMapLayer: return root
	for child in root.get_children():
		var found := _find_tilemap_layer(child)
		if found: return found
	return null
