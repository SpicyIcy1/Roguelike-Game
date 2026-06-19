class_name EscMenu
extends CanvasLayer

var main_panel: Control
var stats_panel: Control

var lbl_hp: Label
var lbl_damage: Label
var lbl_speed: Label
var lbl_cooldown: Label
var lbl_equip: Label


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

	if PlayerData.first_start:
		PlayerData.first_start = false
		call_deferred("open")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		toggle()
		get_viewport().set_input_as_handled()


func open() -> void:
	_show(main_panel)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
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

	lbl_hp       = _stat_row(vbox, "Leben")
	lbl_damage   = _stat_row(vbox, "Schaden")
	lbl_speed    = _stat_row(vbox, "Geschwindigkeit")
	lbl_cooldown = _stat_row(vbox, "Angriff-Cooldown")

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

	if player.equipped_items.is_empty():
		lbl_equip.text = "—"
	else:
		var names: Array[String] = []
		for item in player.equipped_items:
			names.append(item.equipment_name)
		lbl_equip.text = ", ".join(names)
