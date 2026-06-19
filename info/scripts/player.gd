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
var attack_dir: Vector2 = Vector2.ZERO

var can_attack = true
var enemies_in_range: Array = []
var equipped_items: Array[Equipment] = []
enum Direction { UP, DOWN, HORIZONTAL }
var last_direction: Direction = Direction.DOWN

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
	if velocity != Vector2.ZERO:
		$RandiSprites36x36.flip_h = velocity.x < 0

	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			%AnimationPlayer.play("Walk_H")
			last_direction = Direction.HORIZONTAL
		elif velocity.y < 0:
			%AnimationPlayer.play("Walk_Up")
			last_direction = Direction.UP
		elif velocity.y > 0:
			%AnimationPlayer.play("Walk_Down")
			last_direction = Direction.DOWN


	else: #also wenn er sich nicht bewegt
		match last_direction:
			Direction.HORIZONTAL:
				%AnimationPlayer.play("Idle_H") 
			Direction.UP:
				%AnimationPlayer.play("Idle_Up")
			Direction.DOWN:
				%AnimationPlayer.play("Idle_Down")

func _on_attack_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)
			

func _on_attack_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)

# Die Funktion zeichnet je nach MausCurserPosition einen Vektor
func update_attack_area_to_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var vec = (mouse_pos - global_position).normalized()
	if abs(vec.x) > abs(vec.y):
		if vec.x > 0:
			vec = Vector2.RIGHT
		else:
			vec = Vector2.LEFT
	else:
		if vec.y > 0:
			vec = Vector2.DOWN
		else:
			vec = Vector2.UP
			
	var animation_dir = vec
	$AttackArea2D.position = vec * abstand_FightArea
	
func attack():
	if not can_attack:
		return
	can_attack = false
	var cooldown = attack_cooldown
	if enemies_in_range.is_empty():
		# Kein Treffer = längerer Cooldown
		cooldown = attack_cooldown_debuff
	else:
		for enemy in enemies_in_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	
	# Animation hier anpassen
	match attack_dir:
		Vector2.UP:
			%AnimationPlayer.play("slash_up")
		Vector2.DOWN:
			%AnimationPlayer.play("slash_down")
		Vector2.LEFT:
			randi_sprites_36x_36.flip_h = true
			%AnimationPlayer.play("slash_l")
		Vector2.RIGHT:
			randi_sprites_36x_36.flip_h = false
			%AnimationPlayer.play("slash_l")
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
