extends Node2D

@export var enemy_type : PackedScene

func _ready() -> void:
	var marker1 = $Marker2D
	var marker2 = $Marker2D2
	
	spawn(marker1.position, marker2.position)

func spawn(pos1: Vector2, pos2: Vector2) -> void:
	var enemy = enemy_type.instantiate()
	add_child(enemy)
	
	var min_x = min(pos1.x, pos2.x)
	var max_x = max(pos1.x, pos2.x)
	var min_y = min(pos1.y, pos2.y)
	var max_y = max(pos1.y, pos2.y)
	
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)
	
	enemy.position = Vector2(random_x, random_y)
	
