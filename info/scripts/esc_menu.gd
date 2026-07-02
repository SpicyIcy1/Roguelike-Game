class_name EscMenu
extends CanvasLayer

var main_panel: Control
var stats_panel: Control

var lbl_hp: Label
var hp_bar: ProgressBar
var lbl_damage: Label
var lbl_speed: Label
var lbl_cooldown: Label
var lbl_moral: Label
var lbl_equip: Label

var hud_layer: CanvasLayer
var hud_moral: Label
var hud_hp_bar: ProgressBar
var hud_hp_label: Label

var player_ref: Node = null


var hud_hp: Label

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 10
	visible = false

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	main_panel  = _build_main()
	stats_panel = _build_stats()
	add_child(main_panel)
	add_child(stats_panel)

	stats_panel.visible = false

	# HUD lebt in einer eigenen CanvasLayer, damit es unabhängig von der
	# Sichtbarkeit des Pausemenüs ist (Menü ist standardmäßig unsichtbar).
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 9
	add_child(hud_layer)

	hud_layer.add_child(_build_hud())
	PlayerData.moral_changed.connect(_on_moral_changed)

	if PlayerData.first_start:
		PlayerData.first_start = false
		call_deferred("open")
	
	hud_hp = _build_hud_hp()
	hud_layer.add_child(hud_hp)
	PlayerData.hp_changed.connect(_on_hp_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		toggle()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not hud_layer.visible:
		return
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("Player")
	if not player_ref:
		return

	hud_hp_bar.max_value = player_ref.max_health
	hud_hp_bar.value     = player_ref.current_health
	hud_hp_label.text    = "%d / %d" % [player_ref.current_health, player_ref.max_health]

	var ratio: float = 1.0
	if player_ref.max_health > 0:
		ratio = float(player_ref.current_health) / float(player_ref.max_health)
	hud_hp_bar.modulate = _health_bar_color(ratio)


func open() -> void:
	_show(main_panel)
	visible = true
	hud_layer.visible = false
	get_tree().paused = true


func close() -> void:
	visible = false
	hud_layer.visible = true
	get_tree().paused = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _show(panel: Control) -> void:
	main_panel.visible  = false
	stats_panel.visible = false
	panel.visible       = true


# Panels

func _build_main() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 200
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Pause"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var btn_resume = Button.new()
	btn_resume.text = "Weiterspielen"
	btn_resume.pressed.connect(close)
	vbox.add_child(btn_resume)

	var btn_stats = Button.new()
	btn_stats.text = "Statistiken"
	btn_stats.pressed.connect(func(): _show(stats_panel); _refresh_stats())
	vbox.add_child(btn_stats)

	vbox.add_child(HSeparator.new())

	var btn_quit = Button.new()
	btn_quit.text = "Spiel beenden"
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)

	return center


func _build_stats() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 220
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Statistiken"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	lbl_hp = _stat_row(vbox, "Leben")

	hp_bar = _build_health_bar()
	vbox.add_child(hp_bar)
	vbox.add_child(HSeparator.new())

	lbl_damage   = _stat_row(vbox, "Schaden")
	lbl_speed    = _stat_row(vbox, "Geschwindigkeit")
	lbl_cooldown = _stat_row(vbox, "Angriff-Cooldown")
	lbl_moral    = _stat_row(vbox, "Moral")

	vbox.add_child(HSeparator.new())

	lbl_equip = Label.new()
	lbl_equip.text = "—"
	lbl_equip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_equip)

	vbox.add_child(HSeparator.new())

	var btn_back = Button.new()
	btn_back.text = "Zurück"
	btn_back.pressed.connect(func(): _show(main_panel))
	vbox.add_child(btn_back)

	return center


func _build_health_bar() -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	return bar


func _stat_row(parent: VBoxContainer, stat_name: String) -> Label:
	var row = HBoxContainer.new()
	var name_lbl = Label.new()
	name_lbl.text = stat_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	var val_lbl = Label.new()
	row.add_child(val_lbl)
	parent.add_child(row)
	return val_lbl


func _refresh_stats() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	lbl_hp.text       = "%d / %d" % [player.current_health, player.max_health]
	lbl_damage.text   = str(player.damage)
	lbl_speed.text    = str(player.max_speed)
	lbl_cooldown.text = "%.2f s" % player.attack_cooldown
	lbl_moral.text    = "%d  (%s)" % [PlayerData.moral_score, _moral_title(PlayerData.moral_score)]
	lbl_moral.modulate = _moral_color(PlayerData.moral_score)

	hp_bar.max_value = player.max_health
	hp_bar.value     = player.current_health
	var hp_ratio: float = 1.0
	if player.max_health > 0:
		hp_ratio = float(player.current_health) / float(player.max_health)
	hp_bar.modulate = _health_bar_color(hp_ratio)

	if player.equipped_items.is_empty():
		lbl_equip.text = "—"
	else:
		var names: Array[String] = []
		for item in player.equipped_items:
			names.append(item.equipment_name)
		lbl_equip.text = ", ".join(names)


func _build_hud() -> Control:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.position = Vector2(12, 12)
	vbox.custom_minimum_size = Vector2(160, 0)

	hud_hp_bar = ProgressBar.new()
	hud_hp_bar.custom_minimum_size = Vector2(160, 14)
	hud_hp_bar.min_value = 0
	hud_hp_bar.max_value = 100
	hud_hp_bar.value = 100
	hud_hp_bar.show_percentage = false
	vbox.add_child(hud_hp_bar)

	hud_hp_label = Label.new()
	hud_hp_label.text = "-- / --"
	hud_hp_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hud_hp_label)


	hud_moral = Label.new()
	hud_moral.text = _hud_moral_text(PlayerData.moral_score)
	hud_moral.modulate = _moral_color(PlayerData.moral_score)
	vbox.add_child(hud_moral)

	return vbox

func _build_hud_hp() -> Label:
	var lbl = Label.new()
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	lbl.position = Vector2(12, 36) # Positioned below the moral label
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		lbl.text = "HP: %d / %d" % [player.current_health, player.max_health]
	else:
		lbl.text = "HP: —"
	return lbl


func _on_hp_changed(current: int, max_hp: int) -> void:
	hud_hp.text = "HP: %d / %d" % [current, max_hp]


func _on_moral_changed(new_score: int) -> void:
	hud_moral.text = _hud_moral_text(new_score)
	hud_moral.modulate = _moral_color(new_score)


func _hud_moral_text(score: int) -> String:
	var sign_str = "+" if score >= 0 else ""
	return "Moral: %s%d" % [sign_str, score]


func _moral_title(score: int) -> String:
	if score >= 10:
		return "Sehr Cool bro"
	elif score >= 1:
		return "Gut"
	elif score == 0:
		return "Neutral"
	elif score >= -9:
		return "GRRRRRRR"
	else:
		return "Bösewicht"


func _moral_color(score: int) -> Color:
	if score > 0:
		return Color(0.4, 1.0, 0.4)
	elif score < 0:
		return Color(1.0, 0.4, 0.4)
	else:
		return Color(1.0, 1.0, 1.0)


func _health_bar_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.4, 1.0, 0.4)
	elif ratio > 0.25:
		return Color(1.0, 1.0, 0.4)
	else:
		return Color(1.0, 0.4, 0.4)
