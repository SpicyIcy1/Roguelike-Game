class_name Enemy
extends Entity

var weight = 4
var knockback_stop_time = 0.08
var is_in_knockback = false

enum State { IDLE, CHASE, INVESTIGATE, DEAD }
var current_state: State = State.IDLE


@export var SPEED := 20.0
@export var ACCELERATION := 800.0
@export var ATTACK_RANGE := 40.0
@export var PATH_UPDATE_INTERVAL := 0.2


var target: Node2D = null
var last_known_position: Vector2 = Vector2.ZERO

# -- Node refs --
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var path_timer: Timer = $PathUpdateTimer
@onready var sight_area: Area2D = $Sight
@onready var sprite: Sprite2D = $Sprite2D


#  Lifecycle


func _ready() -> void:
	add_to_group("enemy")
	path_timer.wait_time = PATH_UPDATE_INTERVAL
	path_timer.timeout.connect(_update_path)
	path_timer.start()

func _physics_process(delta: float) -> void:
	if not is_in_knockback:
		sprite.flip_h=velocity.x>0 #Spiegelt den Gegnercharakter immer so dass er nach links/rechts in Laufrichtung guckt
	match current_state:
		State.IDLE:
			_apply_friction(delta)
		State.CHASE:
			_move_along_path(delta)
			if _in_attack_range():
				attack()
		State.INVESTIGATE:
			_move_along_path(delta)
			if nav_agent.is_navigation_finished():
				_set_state(State.IDLE)
		State.DEAD:
			pass

#  Pathfinding (Godot handelt wirklich alles)


func _update_path() -> void:
	match current_state:
		State.CHASE:
			if target:
				nav_agent.target_position = target.global_position
		State.INVESTIGATE:
			nav_agent.target_position = last_known_position

func _move_along_path(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
	var next_point := nav_agent.get_next_path_position()
	var direction := (next_point - global_position).normalized()
	velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	move_and_slide()

func _apply_friction(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
	move_and_slide()


#  State

func _set_state(new_state: State) -> void:
	current_state = new_state


#  Sight callbacks


func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		_set_state(State.CHASE)

func _on_sight_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		last_known_position = target.global_position
		target = null
		_set_state(State.INVESTIGATE)


#  Abstract methods (hier absichtlich nicht auf abstract gesetzt damit ich beim konzipieren nicht zu sehr genervt werde)

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	current_health -= amount
	if current_health <= 0:
		die()
		return

	#Knockback durch Attacke wird hier ausgelösst
	is_in_knockback = true
	$AnimationPlayer.stop()
	if knockback_dir == Vector2.ZERO:
		knockback_dir = (global_position - PlayerData.global_position).normalized()
	if knockback_strength <= 0.0:
		knockback_strength = 800.0 / weight
	#Ich würde gerne das der stun die _set_state() blockiert
	velocity = knockback_dir * knockback_strength
	#Abrupterer Knockback
	await get_tree().create_timer(knockback_stop_time).timeout
	velocity = Vector2.ZERO
	
	var base_stun = 0.3
	var stun_time = base_stun / weight
	
	set_physics_process(false)
	await get_tree().create_timer(stun_time).timeout
	set_physics_process(true)
	is_in_knockback = false
	
func die() -> void:
	_set_state(State.DEAD)
	push_warning("Enemy: die() not implemented in ", name)


#  Helpers


func _in_attack_range() -> bool:
	if not target:
		return false
	return global_position.distance_to(target.global_position) <= ATTACK_RANGE
