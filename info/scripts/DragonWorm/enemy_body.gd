class_name EnemyBody
extends Area2D

var health: float
var damage: float
var pause_on_hit: bool = true # whether take_damage briefly disables processing, false for segments so that they dont freeze

func _ready() -> void:
	add_to_group("enemy")

func take_damage(amount: float) -> void:
	health -= amount

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if pause_on_hit:
		process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().create_timer(0.4).timeout
		process_mode = Node.PROCESS_MODE_INHERIT

func die() -> void:
	%AnimationPlayer.play("puff")
	await %AnimationPlayer.animation_finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	body.take_damage(damage)
