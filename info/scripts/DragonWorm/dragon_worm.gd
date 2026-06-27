extends Node2D # extending entity is not an option because its not a characterbody2d


@onready var segments: Array[body_segment] = [] 

const TAIL_COUNT = 2 #the last x segments will be considered the tail

# How many array slots to skip between each segment
const SEGMENT_GAP := 5

var health = 500

const INTERPOLATION_SPEED := 5.0 #head doesnt update its position every frame because we dont want the pcs to explode, without interpolating the movements would be to choppy

func _ready() -> void:
	%Head.z_index = 100 # z index is for ordering
	
	for child in get_children():
		if child != %Head and child is Node2D:
			segments.append(child)
	
	for i in range(segments.size()): #counts the z index down for newer segments
		segments[i].z_index = %Head.z_index - (i + 1)

func _physics_process(delta: float) -> void:
	for i in range(segments.size() - 1, -1, -1): #looping backwards, paramters start, stop, step
		var segment = segments[i]
		
		if i >= segments.size() - TAIL_COUNT:
			segments[i].tail = true
		
		
		#Dead Segments
		if segment.health <= 0:
			segment.die()
			
			segments.remove_at(i)
			
			recalculate_z_indices()
			continue #dead segemtns get skipped
			
		
		var history_index: int
		if i == 0:
			history_index = 0  
		else:
			history_index = 2 + (i * SEGMENT_GAP)
		
		
		if history_index < %Head.position_history.size():
			var target_position: Vector2 = %Head.position_history[history_index]
			segment.global_position = segment.global_position.lerp(target_position, INTERPOLATION_SPEED * delta)

func recalculate_z_indices() -> void:
	for i in range(segments.size()):
		segments[i].z_index = %Head.z_index - (i + 1) 
