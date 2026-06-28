extends Area2D

var speed = 50
var velocity := Vector2.ZERO # newly defined because switch from characterbody2d to area2d
var position_history: Array[Vector2] = []

var time_accumulator := 0.0
const RECORD_INTERVAL := 0.05 # time interval between recording positions
const MAX_HISTORY_SIZE := 50

var health = 200
var damage = 50

func _ready() -> void:
	add_to_group("enemy")

func animate():
	%Sprite2D.flip_h = velocity.x < 0
	
	if velocity.y > 0:
		%Sprite2D.region_rect = Rect2(Vector2(2, 0), Vector2(23, 27))
	else:
		%Sprite2D.region_rect = Rect2(Vector2(66, 5), Vector2(25, 27))


func _physics_process(delta: float) -> void:
	
	
	if health > 0:
		movement(delta)
		
		animate()
		
		time_accumulator += delta # counts time
		
		if time_accumulator >= RECORD_INTERVAL:
			time_accumulator = 0 # resets timer
			
			position_history.push_front(global_position) # inserts at the beginning and shifts back
			
			if position_history.size() > MAX_HISTORY_SIZE: # Info Projekt 1, Diablo IV 0
				position_history.pop_back()



func movement(delta): #mal sehen wie der eigentliche Bossraum aussehen wird wenn das einfach nur ein offener Raum sein wird dann wird das wieder vereinfacht
	%NavigationAgent2D.target_position = PlayerData.global_position
	var next_path_pos: Vector2 = %NavigationAgent2D.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_pos)
	velocity = direction * speed
	global_position += velocity * delta

func take_damage(damage:float):
	health-=damage

func die():
	%AnimationPlayer.play("puff")
	await %AnimationPlayer.animation_finished
	queue_free()


func _on_body_entered(body: Node2D) -> void: #player can be safe when continuing to move with the head but no one is going to do that
	body.take_damage(damage)
	print("Damaged player")
