extends Node2D

func _ready() -> void:
	if PlayerData.spawn_point != "":
		var marker = get_node_or_null(PlayerData.spawn_point)
		if marker:
			$Player.global_position = marker.global_position
		PlayerData.spawn_point = ""  # clear after use
