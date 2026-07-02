extends CharacterBody2D

var speed: float = 350.0
var damage: float = 20.0
var direction: Vector2 = Vector2.RIGHT
var max_distance: float = 500.0
var already_hit: bool = false

var _traveled: float = 0.0

func _ready() -> void:
	rotation = direction.angle()
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if already_hit:
		return

	velocity = direction * speed
	var prev_pos = global_position
	move_and_slide()
	_traveled += prev_pos.distance_to(global_position)

	# Zerstören bei Wandkollision oder maximaler Distanz
	if get_slide_collision_count() > 0 or _traveled >= max_distance:
		_destroy()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if already_hit:
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		_destroy()

func _destroy() -> void:
	already_hit = true
	queue_free()
