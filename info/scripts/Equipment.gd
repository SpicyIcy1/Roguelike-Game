class_name Equipment
extends Resource

enum Type { WEAPON, ARMOR, ACCESSORY }

@export var equipment_name: String = ""
@export var description: String = ""
@export var type: Type = Type.WEAPON

# Stat-Modifikatoren (0 = kein Effekt, negative Werte möglich z.B. schnellerer Angriff)
@export var damage_bonus: float = 0.0
@export var max_health_bonus: float = 0.0
@export var attack_cooldown_bonus: float = 0.0  # negativ = schnellerer Angriff
@export var speed_bonus: float = 0.0
@export var attack_range_bonus: float = 0.0
@export var attack_offset_bonus: float = 0.0


func equip(player) -> void:
	player.damage += damage_bonus
	player.max_health += max_health_bonus
	player.current_health += max_health_bonus
	player.attack_cooldown += attack_cooldown_bonus
	player.max_speed += speed_bonus


# Wird bei "throw"-Input aufgerufen; Subklassen können das überschreiben
func on_secondary_action(player) -> void:
	pass


func unequip(player) -> void:
	player.damage -= damage_bonus
	player.max_health -= max_health_bonus
	player.current_health = minf(player.current_health, player.max_health)
	player.attack_cooldown -= attack_cooldown_bonus
	player.max_speed -= speed_bonus
