@tool
extends EditorScript


const SOURCE_SCENE_PATH := "res://scenes/rooms/Room_0.tscn"
const TARGET_SCENE_PATH := "res://scenes/rooms/Room_01.tscn"
const TILE_SIZE := 16


func _run() -> void:
	if not FileAccess.file_exists(SOURCE_SCENE_PATH):
		print("Error: Source scene not found: ", SOURCE_SCENE_PATH)
		return

	var original_scene: PackedScene = load(SOURCE_SCENE_PATH)
	if not original_scene:
		print("Error: Could not load source scene.")
		return

	var instance: Node = original_scene.instantiate()
	if not instance:
		print("Error: Failed to instantiate source scene.")
		return

	
	var tile_map: TileMapLayer = _find_tilemap_layer(instance)
	if not tile_map:
		print("Error: No TileMapLayer found.")
		instance.free()
		return

	var used_rect := tile_map.get_used_rect()
	var offset_x  := used_rect.position.x
	var size_x    := used_rect.size.x

	#  Mirror tile cells
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

	#Mirror exit markers and swap names
	var exits_node := instance.find_child("Exits", true, false)
	if exits_node:
		for child in exits_node.get_children():
			if child is Node2D:
				_mirror_x(child, offset_x, size_x)

		for child in exits_node.get_children():
			if   child.name == "Exit_W": child.name = "TEMP_Exit_E"
			elif child.name == "Exit_E": child.name = "TEMP_Exit_W"
		for child in exits_node.get_children():
			if   child.name == "TEMP_Exit_E": child.name = "Exit_E"
			elif child.name == "TEMP_Exit_W": child.name = "Exit_W"
	
	var nav_links := instance.find_children("*", "NavigationLink2D", true, false) # would have been better if we had clumped all nav nodes under one Node like with Exits and used a naming scheme
	for link in nav_links: 
		if link is NavigationLink2D:
			_mirror_x(link, offset_x, size_x)
			link.start_position.x = -link.start_position.x #eigentliche position der übergange da wir sie meistens per mouse drag so verschoben haben
			link.end_position.x = -link.end_position.x
	
	
	var spawn_zones := instance.find_children("EnemySpawnZone*", "", true, false)
	
	for zone in spawn_zones:
		if zone is Node2D:
			_mirror_x(zone, offset_x, size_x)
			for child in zone.get_children():
				if child is Marker2D:
					child.position.x = -child.position.x
	
	# Mirror everything else
	for child in instance.get_children():
		if child is Node2D and not child is TileMapLayer and child.name != "Exits" and not child is NavigationLink2D and not child is EnemySpawnZone:
			_mirror_x(child, offset_x, size_x)

	
	var packed := PackedScene.new()
	if packed.pack(instance) == OK:
		if ResourceSaver.save(packed, TARGET_SCENE_PATH) == OK:
			print("Successfully saved mirrored room to: ", TARGET_SCENE_PATH)
		else:
			print("Error: saving")
	else:
		print("Error: packing")

	instance.free()


func _mirror_x(node: Node2D, offset_x: int, size_x: int) -> void:
	var axis := ((offset_x + offset_x + size_x) * TILE_SIZE) / 2.0
	node.position.x = 2.0 * axis - node.position.x


func _find_tilemap_layer(root: Node) -> TileMapLayer:
	if root is TileMapLayer:
		return root
	for child in root.get_children():
		var found := _find_tilemap_layer(child)
		if found:
			return found
	return null
