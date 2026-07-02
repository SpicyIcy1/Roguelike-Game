class_name ThrowingSpearItem
extends Equipment

const SPEAR_SCENE: PackedScene = preload("res://scenes/spear.tscn")

var throw_cooldown: float = 0.8
var _can_throw: bool = true

func _init() -> void:
	equipment_name = "Wurfspeer"
	description = "Ein Speer, der in Richtung des Mauszeigers geworfen wird."
	type = Type.WEAPON

func on_secondary_action(player: Node) -> void:
	if not _can_throw:
		return
	_can_throw = false

	var spear = SPEAR_SCENE.instantiate()
	spear.global_position = player.global_position
	spear.direction = (player.get_global_mouse_position() - player.global_position).normalized()
	spear.damage = 20.0
	# Speer wird als Kind der Parent-Szene hinzugefügt, nicht des Spielers
	player.get_parent().add_child(spear)

	player.get_tree().create_timer(throw_cooldown).timeout.connect(func(): _can_throw = true)
