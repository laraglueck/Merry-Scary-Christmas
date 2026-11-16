# Tests for spec 03: the lobby screen. Clicks buttons like a player.
extends "res://tests/base_test.gd"

const LobbyScene = preload("res://scenes/lobby.tscn")
const RoomCode = preload("res://scripts/net/room_code.gd")


func open_lobby() -> Node:
	var lobby = LobbyScene.instantiate()
	tree.root.add_child(lobby)
	return lobby


func test_lobby_starts_waiting() -> void:
	var lobby := open_lobby()
	assert_contains(text_of(lobby, "StatusLabel"), "create a room or join one", "status")
	assert_eq(text_of(lobby, "CounterLabel"), "Counter: 0", "counter")
	assert_eq(is_disabled(lobby, "AddButton"), true, "+1 disabled")
	assert_eq(is_disabled(lobby, "CreateButton"), false, "create enabled")


func test_create_room_makes_you_player_1_and_counter_works() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	assert_contains(text_of(lobby, "StatusLabel"), "room open", "status")
	assert_contains(text_of(lobby, "PlayersLabel"), "Player 1 (you)", "players")
	assert_eq(is_disabled(lobby, "CreateButton"), true, "create disabled")
	assert_eq(is_disabled(lobby, "JoinButton"), true, "join disabled")
	assert_eq(is_disabled(lobby, "AddButton"), false, "+1 enabled")
	press(lobby, "AddButton")
	assert_eq(text_of(lobby, "CounterLabel"), "Counter: 1", "counter after +1")


func test_join_with_invalid_input_shows_error() -> void:
	var lobby := open_lobby()
	var field := find(lobby, "AddressField")
	if field != null:
		field.text = "hello!"
	press(lobby, "JoinButton")
	assert_contains(text_of(lobby, "StatusLabel"), "not a valid room code or address", "status")
	assert_eq(is_disabled(lobby, "JoinButton"), false, "join still possible")


func test_create_room_shows_room_code() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	var text := text_of(lobby, "RoomCodeLabel")
	assert_true(text.begins_with("Room code: "), "label: " + text)
	assert_true(RoomCode.is_valid_code(text.trim_prefix("Room code: ")), "valid code in: " + text)


# ---------- start button (spec 04) ----------

func open_lobby_with(net: Node) -> Node:
	var lobby = LobbyScene.instantiate()
	lobby.net = net
	tree.root.add_child(lobby)
	return lobby


func test_start_button_hidden_before_hosting() -> void:
	var lobby := open_lobby()
	var start := find(lobby, "StartButton")
	assert_eq(start != null and start.visible, false, "hidden")


func test_start_button_for_host_needs_three_players() -> void:
	var host := make_device("Host")
	host.host_room(47531)
	var lobby := open_lobby_with(host)
	var start := find(lobby, "StartButton")
	if start == null:
		return
	assert_eq(start.visible, true, "visible for the host")
	assert_eq(start.disabled, true, "1 player: disabled")
	var a := make_device("A")
	a.join_room("127.0.0.1", 47531)
	var b := make_device("B")
	await wait_until(func(): return a.connected)
	b.join_room("127.0.0.1", 47531)
	await wait_until(func(): return host.players.size() == 3)
	assert_eq(start.disabled, false, "3 players: enabled")
	press(lobby, "StartButton")
	assert_eq(host.game.get("phase"), "hall", "game started")


func test_start_button_hidden_for_players() -> void:
	var room: Array = await make_full_room(47532)
	var lobby := open_lobby_with(room[1])
	var start := find(lobby, "StartButton")
	assert_eq(start != null and start.visible, false, "hidden for Player 2")
