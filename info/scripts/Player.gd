class_name Player
extends Character

const ACCELERATION = 800.0
const DECELERATION = 1400.0
var in_combat: bool = false
var combat_timer: SceneTreeTimer = null

func _ready() -> void:
	super()
	get_window().grab_focus()

func handle_movement(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * move_speed, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

func _handle_detection(body: Node2D) -> void:
	if in_combat or not body.is_in_group("Enemy"):
		return
	if combat_timer == null:
		combat_timer = get_tree().create_timer(0.5)
		combat_timer.timeout.connect(_start_combat)

func _start_combat() -> void:
	combat_timer = null
	var enemies: Array[Enemy] = []
	for b in detection_area.get_overlapping_bodies():
		if b.is_in_group("Enemy"):
			enemies.append(b as Enemy)
	if enemies.is_empty():
		return
	in_combat = true
	get_tree().get_first_node_in_group("FightManager").start_combat(self, enemies)

func no_fight():
	%DetectionArea.monitoring = false
	%NoFight.start()


func _on_no_fight_timeout() -> void:
	%DetectionArea.monitoring = true
