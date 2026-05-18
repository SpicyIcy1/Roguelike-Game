extends Enemy

var max_health = 100
var current_health = max_health
var weight = 4

func _physics_process(delta: float) -> void:
	super(delta)

func _set_state(new_state: State) -> void:
	# Ich würde gerne für den Stun hier ein If stunned: return einbauen
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

func take_damage(damage_amount: float) -> void:
	current_health -= damage_amount
	if current_health <= 0:
		die()
		return
	
	#Knockback durch Attacke wird hier ausgelösst
	var direction_knockback = (global_position - PlayerData.global_position).normalized()
	var knockback_strenght = 100.0 / weight
	#Ich würde gerne das der stun die _set_state() blockiert
	velocity = direction_knockback * knockback_strenght
	var base_stun = 0.4
	var stun_time = base_stun / weight
	set_physics_process(false)
	await get_tree().create_timer(stun_time).timeout
	set_physics_process(true)
	
func die() -> void:
	super()
	$AnimationPlayer.play("death")
