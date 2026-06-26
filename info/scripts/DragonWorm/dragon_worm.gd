extends Node2D

# This tracks your segments in order: [Segment1, Segment2, Segment3...]
@onready var segments: Array[Node] = [] 

# How many array slots to skip between each segment
const SEGMENT_GAP := 3


const INTERPOLATION_SPEED := 5.0 #head doesnt update its position every frame because we dont want the pcs to explode without interpolating the movements would be to choppy

func _ready() -> void:
	%Head.z_index = 100 # z index is for ordering
	
	for child in get_children():
		if child != %Head and child is Node2D:
			segments.append(child)
	
	for i in range(segments.size()): #counts the z index down for newer segments
		segments[i].z_index = %Head.z_index - (i + 1)

func _physics_process(delta: float) -> void:
	for i in range(segments.size()):
		var history_index: int
		
		if i == 0:
			history_index = 0  #this makes sure the first body segment doesnt stray to far from the head otherwise a notable gap would appear
		else:
			history_index = 2 + (i * SEGMENT_GAP)
		
		if history_index < %Head.position_history.size():
			var target_position: Vector2 = %Head.position_history[history_index]
			
			# lerp stands for linear interpolate
			segments[i].global_position = segments[i].global_position.lerp(target_position, INTERPOLATION_SPEED * delta)
			# two arguments what should get interpolated? -> the position
			# and how fast? -> interpolation speed also account for frame duration so that it's frame rate independent
