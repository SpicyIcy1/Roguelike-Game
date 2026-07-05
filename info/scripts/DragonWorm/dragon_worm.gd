class_name DragonWorm
extends Node2D # extending entity is not an option because its not a CharacterBody2D

@onready var segments: Array[BodySegment] = []
const TAIL_COUNT: int = 2 # the last x segments will be considered the tail
const SEGMENT_GAP: int = 1 # how many array slots to skip between each segment
var is_dying: bool = false # to make sure nothing gets freed twice
const INTERPOLATION_SPEED: float = 5.0 # head doesn't update its position every frame because we don't want the pcs to explode; without interpolating the movements would be too choppy

func _ready() -> void:
	%Head.z_index = 100 # z index is for ordering

	for child: Node in get_children():
		if child != %Head and child is Node2D:
			segments.append(child)

	for i: int in range(segments.size()): # counts the z index down for newer segments
		segments[i].z_index = %Head.z_index - (i + 1)

func _physics_process(delta: float) -> void:
	handle_potential_death()

	if not is_dying:
		handle_movement(delta)

func handle_movement(delta: float) -> void:
	for i: int in range(segments.size() - 1, -1, -1):
		var segment: BodySegment = segments[i]

		if i >= segments.size() - TAIL_COUNT:
			segments[i].tail = true

		if segment.health <= 0:
			segment.die()
			segments.remove_at(i)
			recalculate_z_indices()
			continue

		var history_index: int = i * SEGMENT_GAP

		if history_index < %Head.position_history.size():
			var target_position: Vector2 = %Head.position_history[history_index]
			segment.global_position = segment.global_position.lerp(target_position, INTERPOLATION_SPEED * delta)

func handle_potential_death() -> void:
	if not is_dying:
		if %Head.health <= 0:
			is_dying = true

			var death_tween: Tween = create_tween()
			for i: int in range(segments.size() - 1, -1, -1):
				var segment: BodySegment = segments[i]
				if is_instance_valid(segment):
					death_tween.tween_callback(segment.die)
					death_tween.tween_interval(0.2)
			death_tween.tween_callback(%Head.die) # head dies last
			PlayerData.add_morality(50)
			await death_tween.finished
			queue_free()

func recalculate_z_indices() -> void:
	for i: int in range(segments.size()):
		segments[i].z_index = %Head.z_index - (i + 1)
