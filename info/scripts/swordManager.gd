extends Node2D

@export var stats : Sword

var targets : Array[Node2D] = []

func attack():
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(stats.damage_bonus)
		else:
			push_error("AAAAAH nicht gegner in Ebene3!!!")
	

func _on_area_2d_area_entered(area: Area2D) -> void:
	targets.append(area)
	print("APPEND")


func _on_area_2d_body_entered(body: Node2D) -> void:
	targets.append(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	targets.erase(body)


func _on_area_2d_area_exited(area: Area2D) -> void:
	targets.erase(area)
