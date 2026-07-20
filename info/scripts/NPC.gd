class_name NPC
extends CharacterBody2D

const SWORD_PICKUP_SCENE: PackedScene = preload("res://scenes/weapons/sword_pickup.tscn")

enum State { IDLE, FIGHT }
var current_state: State = State.IDLE

@export var max_health: int = 30
@export var SPEED := 35.0
@export var ACCELERATION := 600.0
@export var GIVE_UP_RANGE := 200.0
@export var ATTACK_COOLDOWN := 1.0
@export var CALM_DOWN_TIME := 10.0
@export var attack_damage := 8
@export var sprite_faces_left := true  # blicken die Walk_Right-Frames nach links?

var current_health: int
var target: Node2D = null
var can_attack := true
var calm_timer: Timer

var in_range := false
var player_ref: Node2D = null

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _ready() -> void:
	add_to_group("npc")
	current_health = max_health

	calm_timer = Timer.new()
	calm_timer.one_shot = true
	calm_timer.wait_time = CALM_DOWN_TIME
	calm_timer.timeout.connect(_stop_fighting)
	add_child(calm_timer)

	_face(Vector2.DOWN, true)  # statisch dastehen, nach unten gerichtet


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		State.FIGHT:
			if not is_instance_valid(target):
				_stop_fighting()
				return
			var to_target := target.global_position - global_position
			var dist := to_target.length()
			# Außer Reichweite -> aufhören
			if dist > GIVE_UP_RANGE:
				_stop_fighting()
				return
			if in_range:
				velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
				_attack()
			else:
				var dir := to_target.normalized()
				velocity = velocity.move_toward(dir * SPEED, ACCELERATION * delta)
				_face(dir, false)
	move_and_slide()


# Wird vom Player-Angriff ausgelöst
func take_damage(amount: float, _knockback_dir: Vector2 = Vector2.ZERO, _knockback_strength: float = 0.0) -> void:
	current_health -= int(amount)
	if current_health <= 0:
		die()
		return
	_start_fighting()


func die() -> void:
	# Tod wird nur durch einen Player-Kill ausgelöst -> zufälliges Schwert droppen.
	# Bessere Schwerter sind seltener (siehe Sword.random_drop()).
	_drop_sword()
	PlayerData.add_morality(-5)
	queue_free()


func _drop_sword() -> void:
	var pickup := SWORD_PICKUP_SCENE.instantiate()
	pickup.sword = Sword.random_drop()
	# An die Szene hängen, nicht an den NPC (der wird gleich freigegeben)
	get_parent().add_child(pickup)
	pickup.global_position = global_position


func _start_fighting() -> void:
	target = get_tree().get_first_node_in_group("Player")
	if target:
		current_state = State.FIGHT
		calm_timer.start()  # 5s-Timer bei jedem Treffer neu starten


func _stop_fighting() -> void:
	current_state = State.IDLE
	target = null
	_face(Vector2.DOWN, true)


func _attack() -> void:
	if not can_attack:
		return
	can_attack = false
	if in_range and is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true


func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		in_range = true
		player_ref = body


func _on_attack_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		in_range = false


# Wählt die Lauf-Animation je nach Richtung. static_frame=true -> nur stehen.
# Robust: macht nichts, wenn kein AnimationPlayer / die Animation fehlt.
func _face(dir: Vector2, static_frame: bool) -> void:
	if anim == null:
		return
	var anim_name := "Walk_Down"
	if abs(dir.x) > abs(dir.y):
		anim_name = "Walk_Right"
		if sprite:
			sprite.flip_h = (dir.x > 0) if sprite_faces_left else (dir.x < 0)
	elif dir.y < 0:
		anim_name = "Walk_Up"
	else:
		anim_name = "Walk_Down"

	if not anim.has_animation(anim_name):
		return
	if static_frame:
		anim.play(anim_name)
		anim.seek(0.0, true)
		anim.pause()
	elif anim.current_animation != anim_name or not anim.is_playing():
		anim.play(anim_name)
