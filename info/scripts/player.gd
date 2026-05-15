extends CharacterBody2D

var max_speed = 120
var acceleration = 50

var max_health = 100
var current_health = max_health

func _ready() -> void:
	get_window().grab_focus() #Damit ich nicht immer "w" in den Code editor schreibe wenn ich das Spiel starte

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	if Input.is_action_just_pressed("ui_accept"):
		attack()
	
	move_and_slide()


func anim():
	pass

func attack():
	%AnimationPlayer.play("punch_l")
