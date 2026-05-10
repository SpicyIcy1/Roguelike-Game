class_name Enemy
extends Character


func _ready() -> void:
	super()


func handle_movement(_delta: float) -> void:
	pass

func _handle_detection(body):
	if body.name == "Player":
		pass

func take_turn(combat: FightManager) -> void:
	combat.apply_damage(combat.player, physical_attack)
	combat.end_turn()
