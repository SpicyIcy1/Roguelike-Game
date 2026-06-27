extends Area2D

var speed = 50
var velocity := Vector2.ZERO # newly defined because switch from characterbody2d to area2d
var position_history: Array[Vector2] = []

var time_accumulator := 0.0
const RECORD_INTERVAL := 0.05 # time interval between recording positions
const MAX_HISTORY_SIZE := 50

func _ready() -> void:
	add_to_group("enemy")

func animate():
	%Sprite2D.flip_h = velocity.x < 0
	
	if velocity.y > 0:
		%Sprite2D.region_rect = Rect2(Vector2(2, 0), Vector2(23, 27))
	else:
		%Sprite2D.region_rect = Rect2(Vector2(66, 5), Vector2(25, 27))


func _physics_process(delta: float) -> void:
	
	velocity = (PlayerData.global_position-global_position).normalized()*speed
	
	
	global_position += velocity * delta
	
	animate()
	
	time_accumulator += delta # counts time
	
	if time_accumulator >= RECORD_INTERVAL:
		time_accumulator = 0 # resets timer
		
		position_history.push_front(global_position) # inserts at the beginning and shifts back
		
		if position_history.size() > MAX_HISTORY_SIZE: # Info Projekt 1, Diablo IV 0
			position_history.pop_back()
