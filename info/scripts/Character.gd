@abstract
class_name Character
extends CharacterBody2D

@export_group("Stats")
@export var max_health: int = 100
@export var physical_attack: float = 25
@export var move_speed: float = 300.0

var current_health: int

@onready var detection_area: Area2D = $DetectionArea

func take_damage(amount: int) -> void:
	current_health -= amount

func is_dead() -> bool:
	return current_health <= 0


func _ready() -> void:
	current_health = max_health
	if not detection_area:
		push_error("No DetectionArea found on " + name)
		return
	detection_area.body_entered.connect(_handle_detection)


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	move_and_slide()


@abstract func handle_movement(_delta: float) -> void
@abstract func _handle_detection(_body: Node2D) -> void
