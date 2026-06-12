extends CharacterBody2D

var max_speed = 120
var acceleration = 50

var max_health = 100
var current_health = max_health
var damage = 10
var attack_cooldown = 0.4
#falls der Spieler ins leere schlägt = längere cooldown
var attack_cooldown_debuff = 3

var reichweite_FightArea: float = 40.0
var abstand_FightArea: float = 40.0

var can_attack = true
var enemies_in_range: Array = []
var equipped_items: Array[Equipment] = []

@onready var randi_sprites_36x_36: Sprite2D = $RandiSprites36x36
@onready var attack_shape: CollisionShape2D = $AttackArea2D/FightArea


func _ready() -> void:
	
	get_window().grab_focus() #Damit ich nicht immer "w" in den Code editor schreibe wenn ich das Spiel starte
	attack_shape.shape.radius = reichweite_FightArea
		
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	anim()
	if Input.is_action_pressed("esc"):
		get_tree().quit()
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	move_and_slide()
	
	update_attack_area_to_mouse()
	if Input.is_action_just_pressed("attack"):
		attack()

func anim():
	
	$RandiSprites36x36.flip_h = velocity.x < 0
	
		
	if abs(velocity.x) > abs(velocity.y):
		%AnimationPlayer.play("Walk_H")
	elif velocity.y < 0:
		%AnimationPlayer.play("Walk_Up")
	elif velocity.y > 0:
		%AnimationPlayer.play("Walk_Down")
	
	if velocity == Vector2.ZERO:
		%AnimationPlayer.play("Idle")

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)
			

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)

# Die Funktion zeichnet je nach MausCurserPosition einen Vektor
func update_attack_area_to_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var unit_vector_FigthArea = (mouse_pos - global_position).normalized()
	var position_FightArea = unit_vector_FigthArea * abstand_FightArea
	$AttackArea2D.position = position_FightArea

func attack():
	if not can_attack:
		return
	can_attack = false
	var cooldown = attack_cooldown
	if enemies_in_range.is_empty():
		# Kein Treffer = längerer Cooldown
		cooldown *= attack_cooldown_debuff
	else:
		for enemy in enemies_in_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	
	# Animation hier anpassen
	var animation_direction = get_global_mouse_position() - global_position
	if abs(animation_direction.x) > abs(animation_direction.y):
		if animation_direction.x > 0:
			randi_sprites_36x_36.flip_h = true
		else:
			randi_sprites_36x_36.flip_h = false
		%AnimationPlayer.play("punch_l")
	else:
		#Godot Koordinatensystem ist auf y-Achse vertauscht
		if animation_direction.y < 0:
			#%AnimationPlayer.play("punch_up")
			%AnimationPlayer.play("punch_l")
		else:
			#%AnimationPlayer.play("punch_down")
			%AnimationPlayer.play("punch_l")
	
	await %AnimationPlayer.animation_finished
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
	
func equip_item(item: Equipment) -> void:
	for existing in equipped_items:
		if existing.type == item.type:
			unequip_item(existing)
			break
	item.equip(self)
	equipped_items.append(item)

func unequip_item(item: Equipment) -> void:
	item.unequip(self)
	equipped_items.erase(item)

func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()
	
func die() -> void:
	get_tree().reload_current_scene()
