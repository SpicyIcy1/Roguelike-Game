extends Node2D

@export var stats : Sword
@onready var attack_area: Area2D = $Area2D

var is_slashing: bool = false
var damaged_targets: Array[Node2D] = []
var total_hits_this_swing: int = 0

#rewritten this way to avoid checking for hits -> detecting zero hits -> then moving the sword through enemies -> dealing 0 damage
func _physics_process(_delta: float) -> void:
	
	if is_slashing: 
		var overlapping = attack_area.get_overlapping_areas() + attack_area.get_overlapping_bodies()
		
		for target in overlapping:
			if is_instance_valid(target) and target.has_method("take_damage"):
				if not damaged_targets.has(target):
					target.take_damage(stats.damage_bonus)
					damaged_targets.append(target)
					total_hits_this_swing += 1


func start_attack() -> void:
	is_slashing = true
	damaged_targets.clear()
	total_hits_this_swing = 0


func end_attack() -> int: #returns hit counter to find out if anything got hit
	is_slashing = false
	return total_hits_this_swing
