class_name Sword
extends Equipment

func _init() -> void:
	equipment_name = "Eisenschwert"
	description = "Das Schwert der Goats."
	type = Type.WEAPON
	damage_bonus = 5.0
	attack_range_bonus = 0.0
	attack_cooldown_bonus = -0.05
