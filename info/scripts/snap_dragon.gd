extends Enemy

var max_health = 50
var current_health = max_health

func _physics_process(delta: float) -> void:
	super(delta)

func _set_state(new_state: State) -> void:
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
	if abs(velocity.x) > abs(velocity.y):
		$AnimationPlayer.play("attack_x")
	else:
		$AnimationPlayer.play("attack_x")

func take_damage(damage_amount: float) -> void:
	current_health -= damage_amount
	if current_health <= 0:
		die()
		
func die() -> void:
	super()
	$AnimationPlayer.play("death")
