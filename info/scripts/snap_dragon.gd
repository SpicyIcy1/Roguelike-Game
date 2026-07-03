extends Enemy

var in_range : bool = false
var player_ref

var sprint_speed := 60.0
var sprint_max_time := 0.5
var sprint_stop_distance := 50.0
var sprint_cooldown := 2
var can_sprint := true

var sprint_distance := 80.0 
var sprint_chance := 0.2

func _physics_process(delta: float) -> void:
	super(delta)
	if current_state == State.CHASE and can_sprint and target:
		_try_sprint()

func _set_state(new_state: State) -> void:
	if is_in_knockback:
		return
	if new_state == current_state: #wirklich kein schöner fix die State machine sollte auch so nicht versuchen immer in den gleichen State zu gehen
		return
	print(name, ": ", State.keys()[current_state], " → ", State.keys()[new_state])
	super(new_state)
	match new_state:
		State.IDLE:        
			$AnimationPlayer.play("idle")
			$Sight.scale = Vector2(1,1)
		State.CHASE:       
			$AnimationPlayer.play("chase_x")
			$Sight.scale = Vector2(2,2) #damit der Gegner den Spieler länger verfolgt sollte dieser einmal gesichtet werden
		State.INVESTIGATE: $AnimationPlayer.play("chase_x") #gibt wohl keine passenden Frames für eine lauf animation

func attack() -> void:
	var dx = PlayerData.global_position.x - global_position.x 
	var dy = PlayerData.global_position.y - global_position.y
	
	if abs(dx) > abs(dy): #der Gegner kann in 4 Richtungen angreifen und soll in die Richtung kämpfen in der der Spieler eher ist
		$AnimationPlayer.play("attack_x")
	else:
		if dy > 0:
			$AnimationPlayer.play("attack_down") 
		else:
			$AnimationPlayer.play("attack_up")
	
	if in_range:
		player_ref.take_damage(damage)

func _try_sprint() -> void:
	var dist := global_position.distance_to(target.global_position)
	if abs(dist - sprint_distance) > 50:
		return
	if randf() > sprint_chance:
		return
	_do_sprint()
	
func _do_sprint() -> void:
	can_sprint = false
	var dir : Vector2 = ($NavigationAgent2D.get_next_path_position() - global_position).normalized()
	var sprint_timer := 0.0
	
	while sprint_timer < sprint_max_time:
		if not target:
			break
		var dist := global_position.distance_to(target.global_position)
		if dist <= sprint_stop_distance:
			break
			
		velocity = dir * sprint_speed
		move_and_slide()
		await get_tree().process_frame
		sprint_timer += get_process_delta_time()
		velocity = Vector2.ZERO
	
	await get_tree().create_timer(sprint_cooldown).timeout
	can_sprint = true
	
func die() -> void:
	super()
	if $AnimationPlayer.has_animation("death"):
		$AnimationPlayer.play("death")
		await $AnimationPlayer.animation_finished
	queue_free()


func _on_attack_body_entered(body: Node2D) -> void:
	in_range = true
	player_ref = body

func _on_attack_body_exited(body: Node2D) -> void:
	in_range = false
