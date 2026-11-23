# Network base (spec 03): one device hosts a room, up to two more join.
# The host is the referee: other players only send requests, the host changes
# the state and sends the new state to every player.
# Used by the lobby (room, counter) and the hall (the shared game, spec 04).
extends Node

const Settings = preload("res://scripts/settings.gd")
const RoomCode = preload("res://scripts/net/room_code.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const TestStart = preload("res://scripts/test_start.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const CharacterRules = preload("res://scripts/rules/character_rules.gd")
const WalkRules = preload("res://scripts/rules/walk_rules.gd")
const SaveGame = preload("res://scripts/save_game.gd")

signal changed       # status, players or counter changed: the screen should update
signal game_changed  # the shared game changed (spec 04)

var status := "Create a room or join one."
var connected := false
var my_index := -1          # 0 = Player 1 (host), 1 = Player 2, 2 = Player 3
var players: Array = []     # player indexes in the room, e.g. [0, 1, 2]
var counter := 0
var room_code := ""         # host: the code others type in, e.g. "KRTW"
var _figure_wait := 0.0     # host: time since the figures were last sent (spec 19)
var _figures_walking := false
var _clock_rest := 0.0      # host: time since the last whole second (spec 13)
var save_path := SaveGame.path()  # host: the save file (spec 15)
var game := {}              # the shared game (spec 04): only the host changes it, everyone gets a copy
var solo := false           # single player: one player, no room, no network (second test round)
var team_name := ""         # the host's team name (or the player's own name): on the leaderboard

var _peer_to_index := {}    # host only: network id -> player index (the host has id 1)
var _rng := RandomNumberGenerator.new()

# Host: tells the Wi-Fi "room KRTW is here" every 0.5 s
var _announce_socket: PacketPeerUDP
var _announce_wait := 0.0
var _room_port := 0
# Player: listens for the announcement of the room code we are looking for
var _search_socket: PacketPeerUDP
var _search_code := ""
var _search_time_left := 0.0


func _ready() -> void:
	_rng.randomize()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _exit_tree() -> void:
	_close()


# True while hosting, searching, joining or connected.
func is_active() -> bool:
	return multiplayer.multiplayer_peer is ENetMultiplayerPeer or _search_socket != null


func _process(delta: float) -> void:
	if _announce_socket != null:
		_announce_wait -= delta
		if _announce_wait <= 0.0:
			_announce_wait = Settings.ANNOUNCE_INTERVAL_SECONDS
			_announce()
	if _search_socket != null:
		_listen_for_room(delta)
	advance_clock(delta)
	advance_figures(delta)


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
	room_code = RoomCode.make_code(_rng)
	_room_port = port
	_announce_socket = PacketPeerUDP.new()
	_announce_socket.set_broadcast_enabled(true)
	_announce_wait = 0.0  # announce right away in the next frame
	var addresses := lan_addresses(Array(IP.get_local_addresses()))
	var plan_b := ", ".join(addresses) if not addresses.is_empty() else "127.0.0.1 (this computer only)"
	_set_status("Room open. Room code: %s  (plan B: join with address %s)" % [room_code, plan_b])


# One field for both: a room code ("KRTW") or the host's address (plan B).
func join(text: String, port := Settings.NETWORK_PORT, timeout := Settings.JOIN_TIMEOUT_SECONDS) -> void:
	var cleaned := text.strip_edges()
	if cleaned.is_valid_ip_address():
		join_room(cleaned, port, timeout)
	elif RoomCode.is_valid_code(cleaned):
		_search_for_room(RoomCode.normalize(cleaned), timeout)
	else:
		_set_status("Not a valid room code or address: \"%s\"" % cleaned)


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


# Single player (second test round): no room and no network. The game runs on this
# computer only; the host's rules work as always, with one player.
func play_alone() -> void:
	if is_active() or connected:
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()  # this computer is the host
	_peer_to_index = {1: 0}
	my_index = 0
	connected = true
	solo = true
	players = [0]
	room_code = ""
	_set_status("Playing alone.")


# One player alone, three in a room.
func players_needed() -> int:
	return 1 if solo else Settings.MAX_PLAYERS


# The name for the leaderboard: trimmed, at most NAME_LENGTH letters.
static func clean_name(text: String) -> String:
	return text.strip_edges().left(Settings.NAME_LENGTH)


# ---------- finding a room by its code ----------

# Host: "MSC1|KRTW|47411" to the whole Wi-Fi and to this computer.
func _announce() -> void:
	var message := RoomCode.announce_message(room_code, _room_port).to_utf8_buffer()
	for address in Settings.DISCOVERY_ADDRESSES:
		_announce_socket.set_dest_address(address, Settings.DISCOVERY_PORT)
		_announce_socket.put_packet(message)


func _search_for_room(code: String, timeout: float) -> void:
	_search_socket = PacketPeerUDP.new()
	var error := _search_socket.bind(Settings.DISCOVERY_PORT, "0.0.0.0")
	if error != OK:
		_search_socket = null
		_set_status("Can't search right now (port %d busy). Try again, or type the host's address." % Settings.DISCOVERY_PORT)
		return
	_search_code = code
	_search_time_left = timeout
	_set_status("Looking for room %s ..." % code)


# Player: read all messages that arrived; join the host with our code.
func _listen_for_room(delta: float) -> void:
	while _search_socket.get_available_packet_count() > 0:
		var text := _search_socket.get_packet().get_string_from_utf8()
		var sender := _search_socket.get_packet_ip()
		var room := RoomCode.parse_announce(text)
		if room.get("code", "") == _search_code:
			_stop_search()
			join_room(sender, room["port"])
			return
	_search_time_left -= delta
	if _search_time_left <= 0.0:
		var code := _search_code
		_stop_search()
		_set_status("Room %s not found. Same Wi-Fi? Room still open? Or type the host's address." % code)


func _stop_search() -> void:
	if _search_socket != null:
		_search_socket.close()
	_search_socket = null
	_search_code = ""


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


# ---------- the shared game (spec 04) ----------

# The clock (spec 13), host only: collects the frame times; every whole second the
# game ticks and everyone gets it. Called every frame by _process (tests call it directly).
func advance_clock(delta: float) -> void:
	if game.is_empty() or not multiplayer.is_server():
		return
	_clock_rest += delta
	var seconds := int(_clock_rest)
	if seconds < 1:
		return
	_clock_rest -= seconds
	if ClockRules.tick(game, seconds) == "":
		_save_game()
		_send_game()
		game_changed.emit()


# Walking figures (spec 19), host only: everybody walks on; while someone walks (and once
# more when the last one arrives) everybody gets the game about 10 times a second.
func advance_figures(delta: float) -> void:
	if game.get("phase") != "hall" or game.get("paused", false) or not multiplayer.is_server():
		return  # paused (spec 26): nobody walks
	var moved := WalkRules.advance(game, delta)
	if not moved and not _figures_walking:
		return
	_figure_wait += delta
	if _figure_wait >= Settings.FIGURE_SYNC_SECONDS or (_figures_walking and not moved):
		_figure_wait = 0.0
		_send_game()
		game_changed.emit()
	_figures_walking = moved


# ---------- save and resume (spec 15) ----------

func has_saved_game() -> bool:
	return SaveGame.exists(save_path)


func can_resume() -> bool:
	return can_start() and has_saved_game() and saved_game_fits()


# A game saved alone goes on only alone, a team game only with three players (playtest:
# a team save resumed alone brought back three figures).
func saved_game_fits() -> bool:
	return bool(SaveGame.load_from(save_path).get("solo", false)) == solo


# Host: the saved game goes on where it stopped, for everyone.
func resume_game() -> void:
	if not can_resume():
		return
	game = SaveGame.load_from(save_path)
	if solo:  # a solo game saved before the fix still had three figures
		var own: Dictionary = game.get("figures", {}).get(0, {})
		game["figures"] = {0: own} if not own.is_empty() else WalkRules.new_figures(1)
	_clock_rest = 0.0
	_send_game()
	game_changed.emit()


# Host: keeps the save up to date. A finished game (e.g. midnight) leaves nothing to resume.
func _save_game() -> void:
	if game.is_empty() or not multiplayer.is_server():
		return
	if game.get("phase") == "hall":
		SaveGame.save(game, save_path)
	else:
		SaveGame.remove(save_path)


# ---------- back to the lobby (spec 17) ----------

# Only the host, and only a finished game (merry, scary, midnight): a running game stays,
# and so does the character selection before it (spec 18).
func can_end_game() -> bool:
	return connected and my_index == 0 and not game.is_empty() and game.get("phase") not in ["hall", "select"]


# Host: clears the finished game for everyone. All are back in the lobby; the room stays
# open with the same players, so "Start game" works at once.
func end_game() -> void:
	if not can_end_game():
		return
	game = {}
	_send_game()
	game_changed.emit()
	changed.emit()


func can_start() -> bool:
	return connected and my_index == 0 and players.size() == players_needed() and game.is_empty()


# Host (spec 18): "Start game" in the lobby. Everyone chooses a character first; the real
# game starts by itself when all three are ready (see _host_apply).
func begin_selection() -> void:
	if not can_start():
		return
	game = CharacterRules.new_selection_game()
	game["players_needed"] = players_needed()
	_send_game()
	game_changed.emit()
	changed.emit()


# Host: create the game and send it to everyone.
func start_game() -> void:
	if not can_start():
		return
	_create_game({})


func _create_game(characters: Dictionary) -> void:
	game = GameRules.new_game(_rng, characters)
	game["solo"] = solo                      # single player: one wire order for all fuses
	if solo:
		game["figures"] = WalkRules.new_figures(1)  # only the own hero walks, no strangers
	game["team_name"] = clean_name(team_name)  # for the leaderboard at the end
	TestStart.apply_if_asked(game, OS.get_cmdline_user_args())  # only when started with "-- test"
	_clock_rest = 0.0
	_save_game()
	_send_game()
	game_changed.emit()


# Any player: "I want to do this". The host decides what happens.
func send_action(action: String, data: Dictionary) -> void:
	if not connected or game.is_empty():
		return
	if multiplayer.is_server():
		_host_apply(1, action, data)
	else:
		_request_action.rpc_id(1, action, data)


@rpc("any_peer", "call_remote", "reliable")
func _request_action(action: String, data: Dictionary) -> void:
	if multiplayer.is_server():
		_host_apply(multiplayer.get_remote_sender_id(), action, data)


# Host only: check, then change (game_rules.gd), then tell everyone.
func _host_apply(sender: int, action: String, data: Dictionary) -> void:
	if not _peer_to_index.has(sender) or game.is_empty():
		return
	GameRules.apply(game, _peer_to_index[sender], action, data)
	if game.get("phase") == "select" and CharacterRules.all_ready(game["selection"], game.get("players_needed", Settings.MAX_PLAYERS)):
		_begin_game_from_selection()
		return
	_save_game()
	_send_game()
	game_changed.emit()


# All three are ready: the real game starts with the chosen characters, for everyone,
# straight in the hall (spec 25: the story came before the lobby).
func _begin_game_from_selection() -> void:
	_create_game(CharacterRules.final_characters(game["selection"]))


func _send_game() -> void:
	for id in _peer_to_index:
		if id != 1:
			_receive_game.rpc_id(id, game)


@rpc("authority", "call_remote", "reliable")
func _receive_game(new_game: Dictionary) -> void:
	game = new_game
	game_changed.emit()


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
	var index: int = _peer_to_index.get(id, -1)
	if _peer_to_index.erase(id):
		if game.get("phase") == "select":  # whoever leaves while choosing loses their pick (spec 18)
			game["selection"].erase(index)
			_send_game()
			game_changed.emit()
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
	solo = false
	my_index = -1
	players = []
	counter = 0
	room_code = ""
	game = {}
	_peer_to_index = {}


func _close() -> void:
	_stop_search()
	if _announce_socket != null:
		_announce_socket.close()
		_announce_socket = null
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


