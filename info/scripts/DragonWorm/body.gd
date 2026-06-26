extends Area2D



var last_position := Vector2.ZERO

func _ready() -> void:
	# Initialize the position tracker
	last_position = global_position

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
	
