extends Enemy

var in_range : bool = false
var player_ref

func _physics_process(delta: float) -> void:
	super(delta)

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
