extends Node

var spawn_point: String = ""
var global_position: Vector2 

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	
	# damit Nepo glücklich wird
	if player:
		global_position = player.global_position
