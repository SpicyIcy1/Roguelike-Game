class_name MapGenerator
extends Node2D


var TILE_SIZE: int = 16
@export var MAX_ROOMS: int = 15
@export var MAX_ROOM_USES: int = 2
@export var MIN_ROOMS: int = 3


const ROOMS_DIR := "res://scenes/rooms/"
const END_DIR := "res://scenes/dead_ends/"
const OPPOSITE := { "North": "South", "South": "North", "East": "West", "West": "East" }


var _layout: DungeonLayout
var _master_pool: Array[RoomData] = []
var _sub_pools: Dictionary = { "North": [], "South": [], "East": [], "West": [] }
var _generation_attempt: int = 0
var _room_use_counts: Dictionary = {}

# Dead-end caps live in a separate pool from regular rooms. Each dead-end
# piece has exactly one entrance exit. It's keyed by the direction THAT
# entrance faces, e.g. a piece whose single exit is "North" is the piece
# you plug into a room's open North exit (entrance facing back at it).
var _dead_end_pool: Array[RoomData] = []
var _dead_end_sub_pools: Dictionary = { "North": [], "South": [], "East": [], "West": [] }
var _placed_dead_ends: Array[RoomData] = []


const MAX_ATTEMPTS := 20

func generate() -> void:
	print("━━━ MapGenerator.generate() START ━━━")
	print("  Config: TILE_SIZE=%d  MAX_ROOMS=%d  MAX_ROOM_USES=%d  MIN_ROOMS=%d" % [
		TILE_SIZE, MAX_ROOMS, MAX_ROOM_USES, MIN_ROOMS
	])

	_phase1_scan_and_parse()

	for attempt in range(1, MAX_ATTEMPTS + 1):
		_generation_attempt = attempt
		print("\n  ── Attempt %d/%d ──" % [attempt, MAX_ATTEMPTS])
		_clear_previous()
		_phase2_layout_loop()
		var placed := _layout.rooms.size()
		if placed < MIN_ROOMS:
			print("  ✗ Only %d room(s) placed (MIN_ROOMS=%d) — retrying..." % [placed, MIN_ROOMS])
			continue
		_phase3_assign_special_rooms()
		_phase4_assemble()
		_phase5_cap_dead_ends()
		print("━━━ MapGenerator.generate() END (attempt %d, %d rooms, %d dead-end caps) ━━━" % [
			attempt, placed, _placed_dead_ends.size()
		])
		return

	push_error("MapGenerator: failed to place >= %d rooms after %d attempts." % [MIN_ROOMS, MAX_ATTEMPTS])


# ─── Phase 1: Directory scan & metadata parsing ───────────────────────────────
func _phase1_scan_and_parse() -> void:
	print("\n── Phase 1: Scan & Parse ──")
	_master_pool.clear()
	for key in _sub_pools:
		_sub_pools[key].clear()

	var dir := DirAccess.open(ROOMS_DIR)
	if dir == null:
		push_error("Phase 1: DirAccess.open('%s') returned null." % ROOMS_DIR)
		return
	print("  Opened directory OK: '%s'" % ROOMS_DIR)

	var all_files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			all_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("  Files found in dir: %d → %s" % [all_files.size(), all_files])

	for fname in all_files:
		var clean_name := fname.trim_suffix(".remap")
		if not clean_name.ends_with(".tscn"):
			print("    SKIP (not .tscn): '%s'" % fname)
			continue
		print("  Parsing: '%s'" % clean_name)
		var room_data := _parse_room_file(clean_name)
		if room_data != null:
			_master_pool.append(room_data)
			for direction in room_data.available_exits.keys():
				_sub_pools[direction].append(room_data)
			print("    ✓ Added to pool | exits: %s | size: %s" % [room_data.available_exits.keys(), room_data.grid_size])
		else:
			print("    ✗ Parse returned null — skipped")

	print("  master_pool size: %d" % _master_pool.size())
	print("  Sub-pool sizes → N:%d  S:%d  E:%d  W:%d" % [
		_sub_pools["North"].size(), _sub_pools["South"].size(),
		_sub_pools["East"].size(),  _sub_pools["West"].size()
	])

	_phase1b_scan_dead_ends()


# ─── Phase 1b: Dead-end directory scan & parsing ──────────────────────────────
# Dead-ends are simpler than rooms: no TileMapLayer requirement, just an
# Exits node with exactly one recognised Exit_N/S/E/W child.
func _phase1b_scan_dead_ends() -> void:
	print("\n── Phase 1b: Scan Dead Ends ──")
	_dead_end_pool.clear()
	for key in _dead_end_sub_pools:
		_dead_end_sub_pools[key].clear()

	var dir := DirAccess.open(END_DIR)
	if dir == null:
		push_error("Phase 1b: DirAccess.open('%s') returned null." % END_DIR)
		return
	print("  Opened directory OK: '%s'" % END_DIR)

	var all_files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			all_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("  Files found in dir: %d → %s" % [all_files.size(), all_files])

	for fname in all_files:
		var clean_name := fname.trim_suffix(".remap")
		if not clean_name.ends_with(".tscn"):
			print("    SKIP (not .tscn): '%s'" % fname)
			continue
		print("  Parsing: '%s'" % clean_name)
		var end_data := _parse_dead_end_file(clean_name)
		if end_data != null:
			_dead_end_pool.append(end_data)
			var facing: String = end_data.available_exits.keys()[0]
			_dead_end_sub_pools[facing].append(end_data)
			print("    ✓ Added to dead-end pool | facing: %s" % facing)
		else:
			print("    ✗ Parse returned null — skipped")

	print("  dead_end_pool size: %d" % _dead_end_pool.size())
	print("  Dead-end sub-pool sizes → N:%d  S:%d  E:%d  W:%d" % [
		_dead_end_sub_pools["North"].size(), _dead_end_sub_pools["South"].size(),
		_dead_end_sub_pools["East"].size(),  _dead_end_sub_pools["West"].size()
	])


func _parse_dead_end_file(file_name: String) -> RoomData:
	var path := END_DIR + file_name
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("  _parse_dead_end_file: load('%s') returned null" % path)
		return null

	var instance: Node = packed.instantiate()

	var exits_node: Node = instance.find_child("Exits", false, false)
	if exits_node == null:
		push_warning("  _parse_dead_end_file: no child named 'Exits' in '%s'" % file_name)
		instance.free()
		return null

	var available_exits: Dictionary = {}
	var dir_map := { "Exit_N": "North", "Exit_S": "South", "Exit_E": "East", "Exit_W": "West" }
	for child in exits_node.get_children():
		if dir_map.has(child.name):
			var pixel_pos: Vector2 = child.position
			var grid_offset := Vector2i(int(pixel_pos.x) / TILE_SIZE, int(pixel_pos.y) / TILE_SIZE)
			available_exits[dir_map[child.name]] = grid_offset
			print("    Exit '%s' → pixel %s → grid offset %s" % [child.name, pixel_pos, grid_offset])
		else:
			print("    Unrecognised exit child name '%s' (expected Exit_N/S/E/W)" % child.name)

	instance.free()

	if available_exits.is_empty():
		push_warning("  _parse_dead_end_file: '%s' has an Exits node but no recognised Exit_N/S/E/W children" % file_name)
		return null
	if available_exits.size() > 1:
		push_warning("  _parse_dead_end_file: '%s' has %d exits, expected exactly 1 — using the first found" % [file_name, available_exits.size()])

	var end_data := RoomData.new()
	end_data.room_file_name = file_name
	end_data.grid_size = Vector2i.ZERO
	end_data.available_exits = available_exits
	for direction in available_exits.keys():
		end_data.connected_rooms[direction] = null
	return end_data


func _parse_room_file(file_name: String) -> RoomData:
	var path := ROOMS_DIR + file_name
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("  _parse_room_file: load('%s') returned null" % path)
		return null

	var instance: Node = packed.instantiate()

	var tile_map: TileMapLayer = _find_first_child_of_type(instance, TileMapLayer)
	if tile_map == null:
		push_warning("  _parse_room_file: no TileMapLayer child in '%s'" % file_name)
		instance.free()
		return null
	var used_rect: Rect2i = tile_map.get_used_rect()
	var grid_size := used_rect.size
	if grid_size == Vector2i.ZERO:
		push_warning("  _parse_room_file: TileMapLayer in '%s' has no painted cells" % file_name)

	var exits_node: Node = instance.find_child("Exits", false, false)
	if exits_node == null:
		push_warning("  _parse_room_file: no child named 'Exits' in '%s'" % file_name)
		instance.free()
		return null

	var available_exits: Dictionary = {}
	var dir_map := { "Exit_N": "North", "Exit_S": "South", "Exit_E": "East", "Exit_W": "West" }
	for child in exits_node.get_children():
		if dir_map.has(child.name):
			var pixel_pos: Vector2 = child.position
			var grid_offset := Vector2i(int(pixel_pos.x) / TILE_SIZE, int(pixel_pos.y) / TILE_SIZE)
			available_exits[dir_map[child.name]] = grid_offset
			print("    Exit '%s' → pixel %s → grid offset %s" % [child.name, pixel_pos, grid_offset])
		else:
			print("    Unrecognised exit child name '%s' (expected Exit_N/S/E/W)" % child.name)

	if available_exits.is_empty():
		push_warning("  _parse_room_file: '%s' has an Exits node but no recognised Exit_N/S/E/W children" % file_name)

	instance.free()

	var room_data := RoomData.new()
	room_data.room_file_name = file_name
	room_data.grid_size = grid_size
	room_data.available_exits = available_exits
	for direction in available_exits.keys():
		room_data.connected_rooms[direction] = null
	return room_data


# ─── Phase 2: Graph layout loop ───────────────────────────────────────────────
func _phase2_layout_loop() -> void:
	print("\n── Phase 2: Layout Loop ──")
	_layout = DungeonLayout.new()

	if _master_pool.is_empty():
		push_error("Phase 2: master_pool is empty.")
		return

	var start_template: RoomData = _find_room_by_name("Room_Start.tscn")
	if start_template == null:
		push_error("Phase 2: 'Room_Start.tscn' not found in master_pool.")
		return
	print("  Start template found: '%s' | exits: %s" % [start_template.room_file_name, start_template.available_exits.keys()])

	var start_room := _duplicate_room(start_template)
	start_room.room_type = RoomData.RoomType.START
	start_room.grid_position = Vector2i.ZERO
	_room_use_counts.clear()

	_layout.register_room(start_room)
	_room_use_counts[start_room.room_file_name] = 1
	print("  Placed START room at grid (0,0)")

	var growth_queue: Array[RoomData] = [start_room]
	var placement_attempts := 0
	var placement_failures := 0

	while not growth_queue.is_empty() and _layout.rooms.size() < MAX_ROOMS:
		var current_room: RoomData = growth_queue.pop_front()
		var directions: Array = current_room.available_exits.keys()
		directions.shuffle()
		print("  Expanding '%s' @ %s | trying directions: %s" % [
			current_room.room_file_name, current_room.grid_position, directions
		])

		for direction in directions:
			if _layout.rooms.size() >= MAX_ROOMS:
				print("    MAX_ROOMS (%d) reached, stopping." % MAX_ROOMS)
				break
			if current_room.connected_rooms.get(direction) != null:
				print("    %s exit already connected, skip." % direction)
				continue

			placement_attempts += 1
			var new_room := _try_place_room(current_room, direction)
			if new_room != null:
				_layout.register_room(new_room)
				growth_queue.push_back(new_room)
				print("    ✓ %s → placed '%s' @ %s (total rooms: %d)" % [
					direction, new_room.room_file_name, new_room.grid_position, _layout.rooms.size()
				])
			else:
				placement_failures += 1
				print("    ✗ %s → no valid placement found" % direction)

	print("  Phase 2 done | rooms: %d | attempts: %d | failures: %d" % [
		_layout.rooms.size(), placement_attempts, placement_failures
	])


func _try_place_room(current_room: RoomData, direction: String) -> RoomData:
	var opposite: String = OPPOSITE[direction]
	var pool: Array = _sub_pools.get(opposite, [])
	if pool.is_empty():
		print("      sub_pool['%s'] is empty — no candidates for %s exit" % [opposite, direction])
		return null

	var candidates: Array = pool.filter(func(r: RoomData) -> bool:
		var uses: int = _room_use_counts.get(r.room_file_name, 0)
		return uses < MAX_ROOM_USES
	)
	if candidates.is_empty():
		print("      all candidates for %s exit at MAX_ROOM_USES (%d) — skipping" % [direction, MAX_ROOM_USES])
		return null

	candidates.shuffle()
	var attempts := mini(candidates.size(), 5)

	for i in range(attempts):
		var template: RoomData = candidates[i]
		var new_room := _duplicate_room(template)

		# Align doors directly: new room's entrance door sits one cell beyond
		# the current room's exit door, so the two doors butt up against
		# each other with no corridor in between.
		var current_exit_local: Vector2i  = current_room.available_exits[direction]
		var current_exit_global: Vector2i = current_room.grid_position + current_exit_local
		var new_entrance_local: Vector2i  = new_room.available_exits[opposite]
		var target_entrance_global: Vector2i = current_exit_global + _direction_vector(direction)
		new_room.grid_position = target_entrance_global - new_entrance_local

		var new_room_rect := Rect2i(new_room.grid_position, new_room.grid_size)
		var space_free    := _layout.is_space_free(new_room_rect)

		var uses: int = _room_use_counts.get(template.room_file_name, 0)
		print("      candidate[%d] '%s' (uses %d/%d) | pos: %s | rect: %s | space_free: %s" % [
			i, template.room_file_name, uses, MAX_ROOM_USES,
			new_room.grid_position, new_room_rect, space_free
		])

		if not space_free:
			continue

		# Commit
		_room_use_counts[template.room_file_name] = uses + 1
		current_room.connected_rooms[direction] = new_room
		new_room.connected_rooms[opposite] = current_room
		return new_room

	return null


# ─── Phase 3: Critical path & special room assignment ─────────────────────────
func _phase3_assign_special_rooms() -> void:
	print("\n── Phase 3: Special Room Assignment ──")
	var start_room := _get_start_room()
	if start_room == null:
		push_error("Phase 3: no START room found in layout")
		return

	var dead_ends: Array[RoomData] = []
	for room in _layout.rooms:
		if room == start_room:
			continue
		var non_null_count := 0
		for dir in room.connected_rooms.keys():
			if room.connected_rooms[dir] != null:
				non_null_count += 1
		if non_null_count == 1:
			dead_ends.append(room)

	print("  Dead ends found: %d" % dead_ends.size())
	for de in dead_ends:
		var dist := (de.grid_position - start_room.grid_position).length()
		print("    '%s' @ %s  dist=%.1f" % [de.room_file_name, de.grid_position, dist])

	dead_ends.sort_custom(func(a: RoomData, b: RoomData) -> bool:
		var da := (a.grid_position - start_room.grid_position).length_squared()
		var db := (b.grid_position - start_room.grid_position).length_squared()
		return da > db
	)

	var assignment := [RoomData.RoomType.BOSS, RoomData.RoomType.TREASURE, RoomData.RoomType.SHOP]
	var label      := ["BOSS", "TREASURE", "SHOP"]
	for idx in range(mini(dead_ends.size(), assignment.size())):
		dead_ends[idx].room_type = assignment[idx]
		print("  Assigned %s → '%s'" % [label[idx], dead_ends[idx].room_file_name])


# ─── Phase 4: Assembly & physical instantiation ───────────────────────────────
func _phase4_assemble() -> void:
	print("\n── Phase 4: Assemble ──")
	print("  Instancing %d rooms..." % _layout.rooms.size())

	for room in _layout.rooms:
		var path := ROOMS_DIR + room.room_file_name
		var packed: PackedScene = load(path)
		if packed == null:
			push_warning("Phase 4: load('%s') failed" % path)
			continue
		var instance: Node2D = packed.instantiate()
		instance.position = Vector2(room.grid_position * TILE_SIZE)
		add_child(instance)
		print("  ✓ Instanced '%s' [%s] at world pos %s" % [
			room.room_file_name, RoomData.RoomType.keys()[room.room_type], instance.position
		])

	print("  Phase 4 done.")


# ─── Phase 5: Dead-end capping ─────────────────────────────────────────────────
# Walk every room placed in the layout and, for each exit that never got
# connected to another room, plug it with a dead-end piece from END_DIR
# whose single entrance exit faces back the way we came (same OPPOSITE
# relationship _try_place_room uses for regular rooms). No reuse-limit
# tracking and no multi-candidate retry: take the first dead-end whose
# pool isn't empty, place it, move on. If a direction's pool is empty the
# exit is logged and left uncapped rather than failing generation.
func _phase5_cap_dead_ends() -> void:
	print("\n── Phase 5: Cap Dead Ends ──")
	_placed_dead_ends.clear()

	if _dead_end_pool.is_empty():
		push_warning("Phase 5: dead_end_pool is empty — no open exits will be capped.")
		return

	var open_exits_found := 0
	var capped := 0
	var uncapped := 0

	for room in _layout.rooms:
		for direction in room.available_exits.keys():
			if room.connected_rooms.get(direction) != null:
				continue  # exit already leads to another room

			open_exits_found += 1
			var opposite: String = OPPOSITE[direction]
			var pool: Array = _dead_end_sub_pools.get(opposite, [])
			if pool.is_empty():
				print("    ✗ '%s' open %s exit — no dead-end faces %s, leaving uncapped" % [
					room.room_file_name, direction, opposite
				])
				uncapped += 1
				continue

			var template: RoomData = pool[0]
			var cap := _duplicate_room(template)
			cap.room_type = RoomData.RoomType.STANDARD

			# Same alignment math as _try_place_room: the cap's entrance
			# door butts up directly against the room's open exit door.
			var exit_local: Vector2i  = room.available_exits[direction]
			var exit_global: Vector2i = room.grid_position + exit_local
			var entrance_local: Vector2i = cap.available_exits[opposite]
			var target_entrance_global: Vector2i = exit_global + _direction_vector(direction)
			cap.grid_position = target_entrance_global - entrance_local

			room.connected_rooms[direction] = cap
			cap.connected_rooms[opposite] = room
			_placed_dead_ends.append(cap)
			capped += 1
			print("    ✓ '%s' open %s exit → capped with '%s' @ %s" % [
				room.room_file_name, direction, cap.room_file_name, cap.grid_position
			])

	print("  Instancing %d dead-end cap(s)..." % _placed_dead_ends.size())
	for cap in _placed_dead_ends:
		var path := END_DIR + cap.room_file_name
		var packed: PackedScene = load(path)
		if packed == null:
			push_warning("Phase 5: load('%s') failed" % path)
			continue
		var instance: Node2D = packed.instantiate()
		instance.position = Vector2(cap.grid_position * TILE_SIZE)
		add_child(instance)
		print("  ✓ Instanced '%s' at world pos %s" % [cap.room_file_name, instance.position])

	print("  Phase 5 done | open exits: %d | capped: %d | uncapped: %d" % [
		open_exits_found, capped, uncapped
	])


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _clear_previous() -> void:
	for child in get_children():
		child.queue_free()


func _duplicate_room(template: RoomData) -> RoomData:
	var r := RoomData.new()
	r.room_file_name = template.room_file_name
	r.grid_size = template.grid_size
	r.room_type = RoomData.RoomType.STANDARD
	r.available_exits = template.available_exits.duplicate(true)
	for direction in template.available_exits.keys():
		r.connected_rooms[direction] = null
	return r


func _get_start_room() -> RoomData:
	for room in _layout.rooms:
		if room.room_type == RoomData.RoomType.START:
			return room
	return null


func _direction_vector(direction: String) -> Vector2i:
	match direction:
		"North": return Vector2i(0, -1)
		"South": return Vector2i(0,  1)
		"East":  return Vector2i(1,  0)
		"West":  return Vector2i(-1, 0)
	return Vector2i.ZERO


func _find_room_by_name(file_name: String) -> RoomData:
	for room in _master_pool:
		if room.room_file_name == file_name:
			return room
	return null


func _find_first_child_of_type(parent: Node, type: Variant) -> Node:
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null
