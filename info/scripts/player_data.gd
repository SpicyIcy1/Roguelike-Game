extends Node

var spawn_point: String = ""
var global_position: Vector2 

func _physics_process(delta: float) -> void:
	global_position = get_tree().get_first_node_in_group("Player").global_position
