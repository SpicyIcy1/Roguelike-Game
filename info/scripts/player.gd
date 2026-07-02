extends Entity

var dev_mode := false
var target_zoom: Vector2 = Vector2(1.0, 1.0)
var zoom_speed: float = 0.025


var max_speed = 120
var acceleration = 50
var attack_cooldown = 0.4
#falls der Spieler ins leere schlägt = längere cooldown
var attack_cooldown_debuff = 1


var attack_dir: Vector2 = Vector2.ZERO

var is_invincible = false #not fair taking damage 10 times a second
var invincibility_t = 1.0 #t for time
var is_attacking = false
var can_attack = true

var npcs_in_range: Array = []
var equipped_items: Array[Equipment] = []
enum Direction { UP, DOWN, HORIZONTAL }
var last_direction: Direction = Direction.DOWN




func _ready() -> void:
	
	get_window().grab_focus() #Damit ich nicht immer "w" in den Code editor schreibe wenn ich das Spiel starte
	
	add_child(EscMenu.new())
	equip_item(ThrowingSpearItem.new())

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	
	var speed_multiplier = 1.0
	if is_attacking:
		speed_multiplier = 0.0
		
	anim()
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed * speed_multiplier, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	move_and_slide()
	
	update_attack_area_to_mouse()
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("Wurf einer Waffe"):
		for item in equipped_items:
			item.on_secondary_action(self)


func _input(event: InputEvent) -> void: #alles was mit input zu tun hat und gleichzeitig nicht physics basiert ist kommt hier hin

	if Input.is_action_just_pressed("DevMode"):
		dev_mode = !dev_mode

	if dev_mode:
		max_speed = 250
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom += Vector2(zoom_speed, zoom_speed)

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom -= Vector2(zoom_speed, zoom_speed)

func _process(delta: float) -> void: #ähnlich wie bei input
	if dev_mode:
		current_health = max_health
	%Camera2D.zoom = %Camera2D.zoom.lerp(target_zoom, 10 * delta)

func anim():
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		%Pivot.scale.x = -1.0 if velocity.x < 0 else 1.0
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
			
	attack_dir = vec
	

func attack():
	is_attacking = true
	if not can_attack:
		return
	can_attack = false
	var cooldown = attack_cooldown
	%WeaponPos.get_child(0,true).attack()
	if len(%WeaponPos.get_child(0).targets)==0:
		# Kein Treffer = längerer Cooldown
		cooldown *= attack_cooldown_debuff
		trigger_slowdown(attack_cooldown_debuff)
	
	# Animation hier anpassen
	match attack_dir:
		Vector2.UP:
			%AnimationPlayer.play("Slash_Up")
			last_direction = Direction.UP
		Vector2.DOWN:
			%AnimationPlayer.play("Slash_Down")
			last_direction = Direction.DOWN
		Vector2.LEFT:
			%Pivot.scale.x = -1
			last_direction = Direction.HORIZONTAL
			%AnimationPlayer.play("Slash_H")
		Vector2.RIGHT:
			%Pivot.scale.x = 1
			last_direction = Direction.HORIZONTAL
			%AnimationPlayer.play("Slash_H")

	await %AnimationPlayer.animation_finished
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
	is_attacking = false
	
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
	if is_invincible:
		return
		
	current_health -= amount
	PlayerData.update_hp(current_health, max_health)
	if current_health <= 0:
		die()
	else:
		# i frames
		trigger_invincibility(invincibility_t)

func trigger_invincibility(duration: float) -> void:
	is_invincible = true
	
	modulate.a = 0.5 #a -> alpha for transparency
	
	await get_tree().create_timer(duration).timeout
	
	
	is_invincible = false
	modulate.a = 1.0

func trigger_slowdown(duration: float) -> void:
	
	modulate = Color(0.4, 0.4, 0.8, 1.0) 
	await get_tree().create_timer(duration).timeout
	# Reset the color back to normal (white means no tint)
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func die() -> void:
	get_tree().call_deferred("reload_current_scene") #to remove the annoying error message


# --Signals
