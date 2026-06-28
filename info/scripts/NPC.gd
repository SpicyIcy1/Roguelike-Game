class_name NPC
extends CharacterBody2D

var max_health: int = 30
var current_health: int = max_health

func _ready() -> void:
	add_to_group("npc")
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("idle")

func take_damage(amount: float, _knockback_dir: Vector2 = Vector2.ZERO, _knockback_strength: float = 0.0) -> void:
	current_health -= int(amount)
	if current_health <= 0:
		die()

func die() -> void:
	PlayerData.add_morality(-5)
	queue_free()
