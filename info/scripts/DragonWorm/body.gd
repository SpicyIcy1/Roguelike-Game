class_name body_segment
extends Area2D


var health = 20
var last_position := Vector2.ZERO

var tail = false # last few(few defined in dragon worm) segments get counted as the tail

func _ready() -> void:
	# Initialize the position tracker
	last_position = global_position
	add_to_group("enemy") #wäre mir personlich im editor lieber haben wir aber bei enemy per skript gemacht also auch hier

func _physics_process(_delta: float) -> void:
	# Calculate how much we moved since the last frame
	var movement = global_position - last_position
	
	# Update our tracking position for the next frame
	last_position = global_position
	
	# Only update animations if the segment actually moved past a tiny deadzone
	if movement.length_squared() > 0.01:
		animate(movement)

func animate(movement: Vector2) -> void:
	%DragonWorm.flip_h = movement.x < 0
	
	if tail:
		%DragonWorm.region_rect = Rect2(Vector2(198,5),Vector2(20,21))

func take_damage(damage:float):
	health-=damage

func die():
	
	%AnimationPlayer.play("puff")
	await %AnimationPlayer.animation_finished
	queue_free()
