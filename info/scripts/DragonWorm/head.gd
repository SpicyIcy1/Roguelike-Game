extends Area2D

var speed = 35
var velocity := Vector2.ZERO 
var position_history: Array[Vector2] = []


const MAX_HISTORY_SIZE := 50
var health = 200
var damage = 25
# ----------------------------------------------------

# Distanz statt Zeit
const MIN_DISTANCE_THRESHOLD := 15.0 
var last_recorded_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemy")
	last_recorded_position = global_position
	
	
	for i in range(MAX_HISTORY_SIZE):
		position_history.append(global_position)

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

		
		if global_position.distance_to(last_recorded_position) >= MIN_DISTANCE_THRESHOLD:
			position_history.push_front(global_position)
			last_recorded_position = global_position 
			
			if position_history.size() > MAX_HISTORY_SIZE:
				position_history.pop_back()

func movement(delta): 
	%NavigationAgent2D.target_position = PlayerData.global_position
	var next_path_pos: Vector2 = %NavigationAgent2D.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_pos)
	velocity = direction * speed
	global_position += velocity * delta

func take_damage(damage: float):
	health -= damage
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) #process mode always
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
	
	tween.tween_interval(0.5)
	
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
	process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.4).timeout
	process_mode = Node.PROCESS_MODE_INHERIT

func die():
	%AnimationPlayer.play("puff")
	await %AnimationPlayer.animation_finished
	queue_free()

func _on_body_entered(body: Node2D) -> void: 
	body.take_damage(damage)
	print("Damaged player")
