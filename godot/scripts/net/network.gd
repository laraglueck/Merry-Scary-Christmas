# Network base (spec 03): one device hosts a room, up to two more join.
# The host is the referee: other players only send requests, the host changes
# the state and sends the new state to every player.
# Used by the lobby now; later the hall uses it for the fuse puzzle.
extends Node

const Settings = preload("res://scripts/settings.gd")

signal changed  # status, players or counter changed: the screen should update

var status := "Create a room or join one."
var connected := false
var my_index := -1          # 0 = Player 1 (host), 1 = Player 2, 2 = Player 3
var players: Array = []     # player indexes in the room, e.g. [0, 1, 2]
var counter := 0

var _peer_to_index := {}    # host only: network id -> player index (the host has id 1)


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _exit_tree() -> void:
	_close()


# True while hosting, joining or connected.
func is_active() -> bool:
	return multiplayer.multiplayer_peer is ENetMultiplayerPeer


# ---------- pure helpers ----------

# Keeps the addresses other devices on the Wi-Fi can reach (IPv4, not 127.x / 169.254.x).
static func lan_addresses(all: Array) -> Array:
	var result := []
	for address in all:
		if ":" in address or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		result.append(address)
	return result


# Lowest free player index (0, 1, 2), or -1 if the room is full.
static func next_free_index(taken: Array) -> int:
	for index in Settings.MAX_PLAYERS:
		if index not in taken:
			return index
	return -1


# ---------- starting ----------

func host_room(port := Settings.NETWORK_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		_set_status("Could not open a room on port %d (error %d)." % [port, error])
		return
	multiplayer.multiplayer_peer = peer
	_peer_to_index = {1: 0}
	my_index = 0
	connected = true
	players = [0]
	counter = 0
	var addresses := lan_addresses(Array(IP.get_local_addresses()))
	if addresses.is_empty():
		_set_status("Room open. No Wi-Fi found: on this computer join with 127.0.0.1.")
	else:
		_set_status("Room open. Others join with: " + ", ".join(addresses))


func join_room(address: String, port := Settings.NETWORK_PORT, timeout := Settings.JOIN_TIMEOUT_SECONDS) -> void:
	address = address.strip_edges()
	if not address.is_valid_ip_address():
		_set_status("Not a valid address: \"%s\". Example: 192.168.1.42" % address)
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		_set_status("Could not connect to %s (error %d)." % [address, error])
		return
	multiplayer.multiplayer_peer = peer
	_set_status("Connecting to %s ..." % address)
	get_tree().create_timer(timeout).timeout.connect(_on_join_timeout.bind(peer, address))


# ---------- the shared counter ----------

func add_one() -> void:
	if not connected:
		return
	if multiplayer.is_server():
		_host_add_one(1)
	else:
		_request_add_one.rpc_id(1)  # ask the host


@rpc("any_peer", "call_remote", "reliable")
func _request_add_one() -> void:
	if multiplayer.is_server():
		_host_add_one(multiplayer.get_remote_sender_id())


# Host only: check, then change, then tell everyone.
func _host_add_one(sender: int) -> void:
	if not _peer_to_index.has(sender):
		return  # not a player in this room (e.g. a rejected 4th device)
	counter += 1
	_send_state()
	changed.emit()


# ---------- host: players come and go ----------

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var index := next_free_index(_peer_to_index.values())
	if index == -1:
		_room_full.rpc_id(id)
		return
	_peer_to_index[id] = index
	players = _sorted_players()
	_welcome.rpc_id(id, index)
	_send_state()
	changed.emit()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	if _peer_to_index.erase(id):
		players = _sorted_players()
		_send_state()
		changed.emit()


func _sorted_players() -> Array:
	var list := _peer_to_index.values()
	list.sort()
	return list


# Sends the state to every player in the room (not to rejected devices).
func _send_state() -> void:
	for id in _peer_to_index:
		if id != 1:
			_receive_state.rpc_id(id, players, counter)


# ---------- player: messages from the host ----------

@rpc("authority", "call_remote", "reliable")
func _welcome(index: int) -> void:
	my_index = index
	connected = true
	_set_status("You are Player %d." % (index + 1))


@rpc("authority", "call_remote", "reliable")
func _receive_state(new_players: Array, new_counter: int) -> void:
	players = new_players
	counter = new_counter
	changed.emit()


@rpc("authority", "call_remote", "reliable")
func _room_full() -> void:
	_close.call_deferred()  # not while the network is still handling this message
	_forget_room()
	_set_status("Room is full (%d players)." % Settings.MAX_PLAYERS)


func _on_connected_to_server() -> void:
	_set_status("Connected. Waiting for the host ...")


func _on_connection_failed() -> void:
	_close.call_deferred()
	_forget_room()
	_set_status("Could not connect.")


func _on_server_disconnected() -> void:
	_close.call_deferred()
	_forget_room()
	_set_status("The host left the room.")


func _on_join_timeout(peer: ENetMultiplayerPeer, address: String) -> void:
	if connected or multiplayer.multiplayer_peer != peer:
		return  # already in the room, or this attempt is over anyway
	_close()
	_forget_room()
	_set_status("Could not connect to %s. Same Wi-Fi? Is the room still open?" % address)


# ---------- small helpers ----------

func _set_status(text: String) -> void:
	status = text
	changed.emit()


func _forget_room() -> void:
	connected = false
	my_index = -1
	players = []
	counter = 0
	_peer_to_index = {}


func _close() -> void:
	if is_active():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
