extends Node

var spawn_point: String = ""
var global_position: Vector2
var first_start: bool = true

var moral_score: int = 0
signal moral_changed(new_score: int)

func add_morality(amount: int) -> void:
	moral_score += amount
	emit_signal("moral_changed", moral_score)

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")

	# damit Nepo glücklich wird
	if player:
		global_position = player.global_position
