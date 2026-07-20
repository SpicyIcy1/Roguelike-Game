extends Node

# Signale, auf die dein MultiplayerMenu lauscht
signal connection_failed
signal connection_succeeded

const MAX_PLAYERS: int = 16
const PLAYER_SCENE: PackedScene = preload("res://minigame/bauer.tscn")


func _ready() -> void:
	# WICHTIG: Verhindert, dass das Netzwerk pausiert, wenn das Spiel pausiert wird!
	process_mode = PROCESS_MODE_ALWAYS
	
	# Signale der Engine mit unseren eigenen Signalen verbinden
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[DEBUG - NetworkManager] Bereit und wartet auf Aktionen. Autoload läuft.")


# Interne Callbacks der Engine

func _on_connection_failed() -> void:
	print("[DEBUG - NetworkManager] Verbindung zum Server fehlgeschlagen! (Timeout oder falsche IP/Port)")
	multiplayer.multiplayer_peer = null
	connection_failed.emit()


func _on_connection_success() -> void:
	print("[DEBUG - NetworkManager] Erfolgreich mit dem Server verbunden!")
	
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		var server_peer = multiplayer.multiplayer_peer.get_peer(1)
		if server_peer:
			server_peer.set_timeout(1000, 2000, 5000)

	connection_succeeded.emit()
	_loaded_into_game()


# Schließt eine aktive Server- oder Client-Verbindung
func shutdown_multiplayer() -> void:
	if multiplayer.multiplayer_peer:
		print("[DEBUG - NetworkManager] Schließe aktive Netzwerkverbindung...")
		if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
			multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func host_game(port: int) -> bool:
	shutdown_multiplayer()

	var peer := ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		print("[DEBUG - NetworkManager] FEHLER beim Erstellen des Servers: ", error)
		return false

	multiplayer.multiplayer_peer = peer
	_loaded_into_game()
	return true


func join_game(ip: String, port: int) -> void:
	shutdown_multiplayer()

	print("[DEBUG - NetworkManager] create_client: ", ip, ":", port)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)

	if error != OK:
		print("[DEBUG - NetworkManager] FEHLER beim Erstellen des Clients: ", error)
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer
	_start_connection_timeout(5.0)



# Timeout Helper Function
func _start_connection_timeout(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	
	# Check connection status directly on multiplayer_peer
	if multiplayer.multiplayer_peer:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			print("[DEBUG - NetworkManager] Verbindung abgebrochen: Timeout nach ", seconds, " Sekunden.")
			shutdown_multiplayer()
			connection_failed.emit()


func _loaded_into_game() -> void:
	print("[DEBUG - NetworkManager] _loaded_into_game() aufgerufen.")
	
	# Der Server spant den ersten Spieler (sich selbst)
	if multiplayer.is_server():
		_spawn_player(1)


func _on_peer_connected(id: int) -> void:
	print("[DEBUG - NetworkManager] Ein anderer Spieler hat sich verbunden! ID: ", id)
	if multiplayer.is_server():
		_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	print("[DEBUG - NetworkManager] Ein Spieler hat die Verbindung getrennt. ID: ", id)
	if multiplayer.is_server():
		_despawn_player(id)


func _spawn_player(peer_id: int) -> void:
	var world = get_tree().current_scene
	
	if PLAYER_SCENE:
		var new_player = PLAYER_SCENE.instantiate()
		new_player.name = str(peer_id) # Extrem wichtig: Name MUSS die Peer-ID sein!
		new_player.position = Vector2(200, 200) # Startposition
		world.add_child(new_player)


func _despawn_player(peer_id: int) -> void:
	var world = get_tree().current_scene
	if world.has_node(str(peer_id)):
		world.get_node(str(peer_id)).queue_free()
