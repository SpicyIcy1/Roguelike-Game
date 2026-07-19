extends NPC
class_name Runner

@export var target_node: Node2D = null # Assign your destination node here in the Inspector

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	# Call the parent NPC class _ready function first
	super._ready()
	SPEED = 50
	# Wait for the first physics frame so the navigation map is fully synced
	await get_tree().physics_frame
	
	if is_instance_valid(target_node):
		nav_agent.target_position = target_node.global_position


func _physics_process(delta: float) -> void:
	# If the runner gets attacked, it will still switch to FIGHT state and attack 
	# the player because of the base class logic. If you ONLY want it to run,
	# you can force the state to remain IDLE, or let the base class handle fighting.
	
	if current_state == State.IDLE:
		_handle_navigation_movement(delta)
	else:
		# Let the base NPC class handle the attack logic if attacked
		super._physics_process(delta)


func _handle_navigation_movement(delta: float) -> void:
	if not is_instance_valid(target_node):
		# No target node? Just decelerate to a stop
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return
		
	# Update target position dynamically in case the destination node moves
	nav_agent.target_position = target_node.global_position

	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		_face(Vector2.DOWN, true) # Stand still looking down
	else:
		
		var next_path_pos: Vector2 = nav_agent.get_next_path_position()
		var dir: Vector2 = (next_path_pos - global_position).normalized()
		
		
		velocity = velocity.move_toward(dir * SPEED, ACCELERATION * delta)
		_face(dir, false) # Animate walking in that direction

	move_and_slide()
