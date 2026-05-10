class_name FightManager
extends Node

var combatants: Array[Character] = []
var current_turn: int = 0
var health_bars: Dictionary = {}
const HealthBarScene: PackedScene = preload("res://scenes/health_bar.tscn")
var player: Player

func start_combat(p: Player, enemies: Array[Enemy]) -> void:
	player = p
	get_tree().paused = true
	%Fight.visible = true
	combatants = [p]
	combatants.append_array(enemies)
	_set_stage()
	_next_turn()

func _set_stage() -> void:
	for child in %HealthBars.get_children():
		child.queue_free()
	for child in %Enemies.get_children():
		child.queue_free()
	health_bars.clear()
	for combatant in combatants:
		if combatant is Enemy:
			var btn = TextureButton.new()
			btn.texture_normal = combatant.get_node("Sprite2D").texture
			btn.disabled = true
			btn.pressed.connect(_on_enemy_targeted.bind(combatant))
			%Enemies.add_child(btn)
		var bar = HealthBarScene.instantiate()
		%HealthBars.add_child(bar)
		bar.setup(combatant)
		health_bars[combatant] = bar

func _next_turn() -> void:
	if combatants.is_empty():
		return
	var acting: Character = combatants[current_turn % combatants.size()]
	%FightUI.visible = acting is Player
	if not acting is Player:
		acting.take_turn(self)

func apply_damage(target: Character, amount: int) -> void:
	target.take_damage(amount)
	health_bars[target].update(target)
	if target.is_dead():
		_handle_death(target)

func _handle_death(target: Character) -> void:
	if target is Player:
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	target.queue_free()
	combatants.erase(target)
	health_bars.erase(target)
	var all_enemies_dead = combatants.all(func(c): return c is Player)
	if all_enemies_dead:
		end_combat()
		return
	current_turn = current_turn % combatants.size()

func end_turn() -> void:
	current_turn += 1
	_next_turn()

func end_combat() -> void:
	get_tree().paused = false
	%Fight.visible = false
	for combatant in combatants:
		if not combatant is Player:
			combatant.queue_free()
	combatants.clear()
	health_bars.clear()
	current_turn = 0
	player.in_combat = false  

func _on_attack_b_pressed() -> void:
	for btn in %Enemies.get_children():
		btn.disabled = false

func _on_enemy_targeted(enemy: Enemy) -> void:
	for btn in %Enemies.get_children():
		btn.disabled = true
	apply_damage(enemy, player.physical_attack)
	end_turn()

func _on_run_pressed() -> void:
	end_combat()
