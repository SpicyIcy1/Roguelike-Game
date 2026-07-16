class_name MultiplayerMenu
extends CanvasLayer

var main_panel: Control
var host_panel: Control
var join_panel: Control

var input_port_host: LineEdit
var input_ip_join: LineEdit
var input_port_join: LineEdit
var lbl_status: Label

var hud_layer: CanvasLayer
var hud_status: Label

var network_ref: Node = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 12
	visible = true # Startet direkt sichtbar, damit du es sofort siehst

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	main_panel = _build_main()
	host_panel = _build_host()
	join_panel = _build_join()
	add_child(main_panel)
	add_child(host_panel)
	add_child(join_panel)

	host_panel.visible = false
	join_panel.visible = false

	# HUD für den Verbindungsstatus im laufenden Spiel
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 9
	add_child(hud_layer)

	hud_layer.add_child(_build_hud())
	
	var lbl_my_ip = Label.new()
	lbl_my_ip.text = "Deine lokale IP: %s" % get_local_ip()
	add_child(lbl_my_ip)
	
	print("[DEBUG - Menu] Suche nach Autoload '/root/NetworkManager'...")
	if has_node("/root/NetworkManager"):
		network_ref = get_node("/root/NetworkManager")
		network_ref.connection_failed.connect(_on_connection_failed)
		network_ref.connection_succeeded.connect(_on_connection_success)
		print("[DEBUG - Menu] NetworkManager erfolgreich gefunden und Signale verbunden!")
	else:
		print("[DEBUG - Menu] FEHLER: '/root/NetworkManager' wurde NICHT im SceneTree gefunden!")


func _unhandled_input(event: InputEvent) -> void:
	# Nutzt standardmäßig die "Escape"-Taste von Godot
	if event.is_action_pressed("ui_cancel"):
		print("[DEBUG - Menu] ESC-Taste gedrückt. Toogle Menü.")
		toggle()
		get_viewport().set_input_as_handled()


func open() -> void:
	print("[DEBUG - Menu] Menü geöffnet. Spiel pausiert.")
	_show(main_panel)
	visible = true
	hud_layer.visible = false
	get_tree().paused = true


func close() -> void:
	print("[DEBUG - Menu] Menü geschlossen. Spiel fortgesetzt.")
	visible = false
	hud_layer.visible = true
	get_tree().paused = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _show(panel: Control) -> void:
	main_panel.visible = false
	host_panel.visible = false
	join_panel.visible = false
	panel.visible = true


# Panels

func _build_main() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 220
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Multiplayer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var btn_host_menu = Button.new()
	btn_host_menu.text = "Server hosten"
	btn_host_menu.pressed.connect(func(): _show(host_panel))
	vbox.add_child(btn_host_menu)

	var btn_join_menu = Button.new()
	btn_join_menu.text = "Server beitreten"
	btn_join_menu.pressed.connect(func(): _show(join_panel))
	vbox.add_child(btn_join_menu)

	vbox.add_child(HSeparator.new())

	var btn_back = Button.new()
	btn_back.text = "Schließen"
	btn_back.pressed.connect(close)
	vbox.add_child(btn_back)

	return center


func _build_host() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 220
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Server erstellen"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# Port-Eingabe
	var row_port = HBoxContainer.new()
	var lbl_port = Label.new()
	lbl_port.text = "Port:"
	lbl_port.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_port.add_child(lbl_port)
	
	input_port_host = LineEdit.new()
	input_port_host.text = "23500"
	input_port_host.custom_minimum_size.x = 100
	row_port.add_child(input_port_host)
	vbox.add_child(row_port)

	vbox.add_child(HSeparator.new())

	var btn_start_host = Button.new()
	btn_start_host.text = "Server starten"
	btn_start_host.pressed.connect(_on_host_pressed)
	vbox.add_child(btn_start_host)

	var btn_back = Button.new()
	btn_back.text = "Zurück"
	btn_back.pressed.connect(func(): _show(main_panel))
	vbox.add_child(btn_back)

	return center


func _build_join() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 240
	center.add_child(vbox)

	var title = Label.new()
	title.text = "Server beitreten"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# IP-Eingabe
	var row_ip = HBoxContainer.new()
	var lbl_ip = Label.new()
	lbl_ip.text = "IP-Adresse:"
	lbl_ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_ip.add_child(lbl_ip)
	
	input_ip_join = LineEdit.new()
	input_ip_join.text = "127.0.0.1"
	input_ip_join.custom_minimum_size.x = 120
	row_ip.add_child(input_ip_join)
	vbox.add_child(row_ip)

	# Port-Eingabe
	var row_port = HBoxContainer.new()
	var lbl_port = Label.new()
	lbl_port.text = "Port:"
	lbl_port.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_port.add_child(lbl_port)
	
	input_port_join = LineEdit.new()
	input_port_join.text = "23500"
	input_port_join.custom_minimum_size.x = 120
	row_port.add_child(input_port_join)
	vbox.add_child(row_port)

	vbox.add_child(HSeparator.new())

	lbl_status = Label.new()
	lbl_status.text = ""
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_status)

	var btn_start_join = Button.new()
	btn_start_join.text = "Verbinden"
	btn_start_join.pressed.connect(_on_join_pressed)
	vbox.add_child(btn_start_join)

	var btn_back = Button.new()
	btn_back.text = "Zurück"
	btn_back.pressed.connect(func(): _show(main_panel); lbl_status.text = "")
	vbox.add_child(btn_back)

	return center


func _build_hud() -> Control:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.position = Vector2(12, 12)
	vbox.custom_minimum_size = Vector2(200, 0)

	hud_status = Label.new()
	hud_status.text = "Offline"
	hud_status.modulate = _status_color("offline")
	vbox.add_child(hud_status)

	return vbox


# Netzwerk-Aktionen

func _on_host_pressed() -> void:
	var port = input_port_host.text.to_int()
	if port <= 0:
		port = 23500
	
	print("[DEBUG - Menu] Start-Host Button gedrückt. Port: ", port)
	
	if network_ref and network_ref.has_method("host_game"):
		var success = network_ref.host_game(port)
		if success:
			hud_status.text = "Host (Port: %d)" % port
			hud_status.modulate = _status_color("hosting")
			close()
	else:
		print("[DEBUG - Menu] FEHLER: Kein NetworkManager referenziert beim Starten des Hosts!")


func _on_join_pressed() -> void:
	var ip = input_ip_join.text.strip_edges()
	var port = input_port_join.text.to_int()
	if ip == "":
		ip = "127.0.0.1"
	if port <= 0:
		port = 23500

	print("[DEBUG - Menu] Verbinden Button gedrückt. IP: %s | Port: %d" % [ip, port])
	lbl_status.text = "Verbinde..."
	lbl_status.modulate = _status_color("connecting")

	if network_ref and network_ref.has_method("join_game"):
		network_ref.join_game(ip, port)
	else:
		print("[DEBUG - Menu] FEHLER: Kein NetworkManager referenziert beim Beitreten!")


# Callbacks für Netzwerk-Events

func _on_connection_failed() -> void:
	print("[DEBUG - Menu] Event empfangen: Verbindung fehlgeschlagen.")
	lbl_status.text = "Verbindung fehlgeschlagen!"
	lbl_status.modulate = _status_color("failed")
	hud_status.text = "Offline"
	hud_status.modulate = _status_color("offline")


func _on_connection_success() -> void:
	print("[DEBUG - Menu] Event empfangen: Verbindung ERFOLGREICH.")
	lbl_status.text = "Verbunden!"
	lbl_status.modulate = _status_color("connected")
	hud_status.text = "Verbunden"
	hud_status.modulate = _status_color("connected")
	close()


# Hilfsfunktionen

func _status_color(status: String) -> Color:
	match status:
		"connected", "hosting":
			return Color(0.4, 1.0, 0.4) # Grün
		"connecting":
			return Color(1.0, 1.0, 0.4) # Gelb
		"failed":
			return Color(1.0, 0.4, 0.4) # Rot
		_:
			return Color(1.0, 1.0, 1.0) # Weiß (Offline)
func get_local_ip() -> String:
	var ips: Array = IP.get_local_addresses()
	for ip in ips:
		if ":" in ip:
			continue
		if ip.begins_with("127."):
			continue
		if ip.begins_with("169.254."):
			continue
		# Docker/Bridge typischerweise 172.16-172.31 (inkl. 172.17/172.18)
		if ip.begins_with("172."):
			continue
		# Nimm die erste "vernünftige" IPv4
		return ip
	return "Keine brauchbare IP gefunden"
