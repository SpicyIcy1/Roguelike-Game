class_name BodySegment
extends EnemyBody

var last_position: Vector2 = Vector2.ZERO
var tail: bool = false # last few (count defined in DragonWorm) segments get counted as the tail

func _init() -> void:
	health = 30.0
	damage = 12.0 # half the head's damage
	pause_on_hit = false

func _ready() -> void:
	super._ready()
	last_position = global_position

func _physics_process(_delta: float) -> void:
	var movement: Vector2 = global_position - last_position
	last_position = global_position

	if movement.length_squared() > 0.01:
		animate(movement)

func animate(movement: Vector2) -> void:
	%DragonWorm.flip_h = movement.x < 0

	if tail:
		%DragonWorm.region_rect = Rect2(Vector2(198, 5), Vector2(20, 21))
