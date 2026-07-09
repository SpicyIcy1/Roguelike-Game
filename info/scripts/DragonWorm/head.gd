class_name DragonHead
extends EnemyBody

var speed: float = 35.0
var velocity: Vector2 = Vector2.ZERO
var position_history: Array[Vector2] = []
const MAX_HISTORY_SIZE: int = 50
const MIN_DISTANCE_THRESHOLD: float = 5.0
var last_recorded_position: Vector2 = Vector2.ZERO

func _init() -> void:
	health = 200.0
	damage = 25.0

func _ready() -> void:
	randomize()
	super._ready()
	last_recorded_position = global_position
	for i: int in range(MAX_HISTORY_SIZE):
		position_history.append(global_position)

func _physics_process(delta: float) -> void:
	if health > 0:
		movement(delta)
		animate()

		if global_position.distance_to(last_recorded_position) >= MIN_DISTANCE_THRESHOLD:
			position_history.push_front(global_position)
			last_recorded_position = global_position

			if position_history.size() > MAX_HISTORY_SIZE:
				position_history.pop_back()

func movement(delta: float) -> void:
	%NavigationAgent2D.target_position = PlayerData.global_position
	var next_path_pos: Vector2 = %NavigationAgent2D.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_pos)
	velocity = direction * speed
	global_position += velocity * delta

func animate() -> void:
	%Sprite2D.flip_h = velocity.x < 0

	if velocity.y > 0:
		%Sprite2D.region_rect = Rect2(Vector2(2, 0), Vector2(23, 27))
	else:
		%Sprite2D.region_rect = Rect2(Vector2(66, 5), Vector2(25, 27))
	
