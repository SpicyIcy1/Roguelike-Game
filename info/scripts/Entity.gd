class_name Entity
extends CharacterBody2D

var max_health = 100
var current_health = max_health
var damage = 10

func take_damage(amount: float) -> void:
	push_warning("Entity: take_damage() not implemented in ", name)

func attack() -> void:
	push_warning("Entity: attack() not implemented in ", name)

func die() -> void:
	push_warning("Entity: die() not implemented in ", name)
