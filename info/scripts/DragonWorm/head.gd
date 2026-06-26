extends CharacterBody2D

var speed = 100
var position_history: Array[Vector2] = []

var time_accumulator := 0.0
const RECORD_INTERVAL := 0.05 # time intervall between recording positions
const MAX_HISTORY_SIZE := 50


func animate():
	%Sprite2D.flip_h = velocity.x < 0
	
	if velocity.y > 0:
		%Sprite2D.region_rect = Rect2(Vector2(2, 0), Vector2(23, 27))
	else:
		%Sprite2D.region_rect = Rect2(Vector2(66, 5), Vector2(25, 27))


func _physics_process(delta: float) -> void:
	velocity = (get_global_mouse_position()-global_position).normalized()*speed # oh yeah einheitsvektor mal geschwindigkeit Weimar wäre stolz
	move_and_slide()
	
	animate()
	
	time_accumulator += delta # counts time
	
	if time_accumulator >= RECORD_INTERVAL:
		time_accumulator = 0 #resets timer
		
		position_history.push_front(global_position) #push front equals inserting at the beginning of the array and shifting everything back
		
		if position_history.size() > MAX_HISTORY_SIZE: #Memory leak avoidance Info Projekt 1, Diablo IV 0
			position_history.pop_back()
