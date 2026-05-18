extends CharacterBody2D

var max_speed = 120
var acceleration = 50

var max_health = 100
var current_health = max_health
var damage = 10
var attack_cooldown = 0.4
var attack_cooldown_debuff = 2
var reichweite_FightArea: float = 40.0

var can_attack = true
var enemies_in_range: Array = []

@onready var randi_sprites_36x_36: Sprite2D = $RandiSprites36x36
@onready var attack_shape: CollisionShape2D = $AttackArea2D/FightArea

func _ready() -> void:
	get_window().grab_focus() #Damit ich nicht immer "w" in den Code editor schreibe wenn ich das Spiel starte
	attack_shape.shape.radius = reichweite_FightArea
		
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("attack"):
		attack()

func anim():
	pass

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)

func attack():
	if not can_attack:
		return
	if enemies_in_range.is_empty():
		can_attack = false
		#Die Animation muss hier je nach Gegner Position gedreht werden
		%AnimationPlayer.play("punch_l")
		await %AnimationPlayer.animation_finished
		await get_tree().create_timer(attack_cooldown * attack_cooldown_debuff).timeout
		can_attack = true
	
	can_attack = false
	
	#Die Animation muss hier je nach Gegner Position gedreht werden
	randi_sprites_36x_36.flip_h = false
	%AnimationPlayer.play("punch_l")
	
	await %AnimationPlayer.animation_finished
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
