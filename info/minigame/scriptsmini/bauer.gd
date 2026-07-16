extends CharacterBody2D

const SPEAR_SCENE = preload("res://scenes/spear.tscn") 

const SPEED = 175.0
const JUMP_VELOCITY = -400.0

# Teeworlds Hook Constants
const HOOK_MAX_LENGTH = 200.0   # Maximum distance the rope can stretch
const HOOK_PULL_FORCE = 12.0    # Lerp weight factor for smooth elasticity
const HOOK_DAMPING = 0.15       # Absorbs the "bounciness"
const HOOK_SWING_SPEED = 400.0  # Control force while swinging
const AIR_DRAG = 0.99           # General air resistance

# PROJECTILE HOOK CONSTANTS
const HOOK_LAUNCH_SPEED = 400.0 # How fast the hook projectile travels through the air

# Grappling Hook States & Variables
enum HookState { IDLE, FIRING, LATCHED, RETRACTING }
var hook_state: HookState = HookState.IDLE

var hook_point: Vector2 = Vector2.ZERO          # The point where the hook currently is (or latched)
var hook_dir: Vector2 = Vector2.ZERO           # Flight direction
var current_rope_length: float = 0.0

# Double Jump Variables
var has_double_jump: bool = false

var max_health = 200
var current_health = max_health

@onready var ray_cast_2d: RayCast2D = $RayCast2D


func _enter_tree() -> void:
	# Setze die Netzwerk-Autorität basierend auf dem Namen des Nodes (unserer Peer-ID)
	var peer_id = name.to_int()
	if peer_id > 0:
		set_multiplayer_authority(peer_id)
		print("[DEBUG - Player] Autorität im _enter_tree gesetzt für Peer: ", peer_id)


func _ready() -> void:
	position = Vector2(200,200)
	if is_multiplayer_authority():
		get_window().grab_focus()
		
		$Camera2D.enabled = true
		# zur sicherheit
		$Camera2D.make_current() 
	else:
		# Für alle ANDEREN Spieler auf deinem Bildschirm schalten wir die Kamera aus!
		if has_node("Camera2D"):
			$Camera2D.enabled = false

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_handle_grapple_input()
	
	if current_health <= 0:
		current_health = max_health
		position = Vector2(200,200)

	match hook_state:
		HookState.IDLE:
			_process_normal_movement(delta)
			if has_node("Line2D"):
				$Line2D.points = []
				
		HookState.FIRING:
			_process_normal_movement(delta)
			_process_hook_projectile(delta)
			
		HookState.LATCHED:
			_process_teeworlds_grapple(delta)
			
		HookState.RETRACTING:
			_process_normal_movement(delta)
			_process_hook_retraction(delta)
	
	if Input.is_action_just_pressed("mini_shoot"):
		# Speerwurf über das Netzwerk triggern
		_shoot_networked()
	
	_anim()
	move_and_slide()

func _handle_grapple_input() -> void:
	if Input.is_action_just_pressed("mouse_click") and hook_state == HookState.IDLE:
		hook_dir = (get_global_mouse_position() - global_position).normalized()
		hook_point = global_position # Start projectile at player position
		hook_state = HookState.FIRING
			
	if Input.is_action_just_released("mouse_click") or Input.is_action_just_pressed("ui_accept"):
		if hook_state == HookState.FIRING or hook_state == HookState.LATCHED:
			hook_state = HookState.RETRACTING

func _process_normal_movement(delta: float) -> void:
	if is_on_floor():
		has_double_jump = true
	else:
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif has_double_jump:
			velocity.y = JUMP_VELOCITY
			$AnimationPlayer.play("puff")
			has_double_jump = false 

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _process_hook_projectile(delta: float) -> void:
	# Project where the hook will move this frame
	var next_hook_point = hook_point + (hook_dir * HOOK_LAUNCH_SPEED * delta)
	
	# Configure the RayCast to scan from current hook position to next hook position
	ray_cast_2d.global_position = hook_point
	ray_cast_2d.target_position = ray_cast_2d.to_local(next_hook_point)
	ray_cast_2d.force_raycast_update()
	
	if ray_cast_2d.is_colliding():
		# It hit something! Latched!
		hook_point = ray_cast_2d.get_collision_point()
		hook_state = HookState.LATCHED
		current_rope_length = global_position.distance_to(hook_point)
		has_double_jump = true
	else:
		# Keep flying
		hook_point = next_hook_point
		
		# Out of bounds check: Did it fly past max length?
		if global_position.distance_to(hook_point) >= HOOK_MAX_LENGTH:
			hook_state = HookState.RETRACTING
			
	# Draw projectile line
	if has_node("Line2D"):
		$Line2D.points = [Vector2.ZERO, to_local(hook_point)]

func _process_hook_retraction(delta: float) -> void:
	# Bring hook point back to player quickly
	hook_point = hook_point.move_toward(global_position, HOOK_LAUNCH_SPEED * 1.5 * delta)
	
	if hook_point.distance_to(global_position) < 10.0:
		hook_state = HookState.IDLE
		
	if has_node("Line2D"):
		$Line2D.points = [Vector2.ZERO, to_local(hook_point)]

func _process_teeworlds_grapple(delta: float) -> void:
	var to_hook = hook_point - global_position
	var distance = to_hook.length()
	var current_dir = to_hook.normalized()
	
	# If player gets yanked/pushed past maximum radius, break the hook state
	if distance > HOOK_MAX_LENGTH + 20.0:
		hook_state = HookState.RETRACTING
		return

	# 1. Apply gravity so physical drops feel natural
	velocity += get_gravity() * delta
	
	# 2. Teeworlds Rope Retraction: actively shrink the rope length to pull the player up
	# This ensures that even if you start on the floor, the "rope" gets shorter and lifts you.
	const RETRACT_SPEED = 250.0 # Adjust this to make the upward pull faster/slower
	current_rope_length = max(20.0, current_rope_length - RETRACT_SPEED * delta)
	
	# 3. Pulling Force (Teeworlds physics style)
	# If we are further than the current allowed rope length, OR if we are on the floor trying to get up:
	if distance > current_rope_length or is_on_floor():
		# Dampen velocity going away from the hook point
		var current_pull_speed = velocity.dot(current_dir)
		if current_pull_speed < 0:
			velocity -= current_dir * current_pull_speed * HOOK_DAMPING
			
		# Strongly pull towards the hook point
		var target_velocity = current_dir * HOOK_SWING_SPEED
		velocity = velocity.lerp(target_velocity, HOOK_PULL_FORCE * delta)
	
	# 4. Swing/Air Control
	var swing_input = Input.get_axis("ui_left", "ui_right")
	if swing_input != 0:
		var perpendicular_dir = Vector2(-current_dir.y, current_dir.x)
		if perpendicular_dir.x * swing_input < 0:
			perpendicular_dir = -perpendicular_dir
		velocity += perpendicular_dir * HOOK_SWING_SPEED * delta

	# Apply air resistance
	velocity *= AIR_DRAG
	
	# Update line rendering
	if has_node("Line2D"):
		$Line2D.points = [Vector2.ZERO, to_local(hook_point)]

func _anim() -> void:
	
	if $AnimationPlayer.current_animation == "puff" and $AnimationPlayer.is_playing():
		return

	if abs(velocity.x) > 10:
		if velocity.x > 0:
			$Pivot.scale.x = 1
		elif velocity.x < 0:
			$Pivot.scale.x = -1
		
	if velocity.x != 0:
		$AnimationPlayer.play("walk_h")
	else:
		$AnimationPlayer.play("idle")


func _shoot_networked() -> void:
	var target_dir = (get_global_mouse_position() - global_position).normalized()
	var spawn_pos = %WeaponPos.global_position
	
	# Schicke den Schuss-Befehl an alle (inklusive uns selbst)
	_rpc_spawn_spear.rpc(spawn_pos, target_dir)


@rpc("any_peer", "call_local", "reliable")
func _rpc_spawn_spear(spawn_pos: Vector2, target_dir: Vector2) -> void:
	var spear_instance = SPEAR_SCENE.instantiate()
	spear_instance.global_position = spawn_pos
	
	if spear_instance.has_method("set_direction"):
		spear_instance.set_direction(target_dir)
	elif "direction" in spear_instance:
		spear_instance.direction = target_dir
		
	spear_instance.rotation = target_dir.angle()
	get_parent().add_child(spear_instance)

func take_damage(damage_taken:int):
	current_health-=damage_taken
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
