@tool #das hier ist nichtmal ein Skript das vom Spiel direkt genutzt wird, hab ich aber für Room 3 gebraucht
extends EditorScript

const OLD_SOURCE_ID: int = 4
const NEW_SOURCE_ID: int = 0

func _run() -> void:
	var selection = EditorInterface.get_selection()
	var target_nodes = selection.get_selected_nodes()
	
	if target_nodes.is_empty():
		print("Error: Kein TileMapLayer ausgewählt")
		return
	var map = target_nodes[0]
	
	if map is TileMapLayer:
		var used_cells = map.get_used_cells()
		var changed_count = 0
		
		for cell in used_cells:
			var source_id = map.get_cell_source_id(cell)
			
			if source_id == OLD_SOURCE_ID:
				var atlas_coords = map.get_cell_atlas_coords(cell)
				var alternative_tile = map.get_cell_alternative_tile(cell)
				
				map.set_cell(cell, NEW_SOURCE_ID, atlas_coords, alternative_tile)
				changed_count += 1
				
		print("Swapped ", changed_count, " tiles from ID ", OLD_SOURCE_ID, " to ", NEW_SOURCE_ID)
	else:
		print("Error: Das muss ne TileMapLayer sein")
