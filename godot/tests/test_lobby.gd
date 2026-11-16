# Tests for spec 03: the lobby screen. Clicks buttons like a player.
extends "res://tests/base_test.gd"

const LobbyScene = preload("res://scenes/lobby.tscn")


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


func test_join_with_invalid_address_shows_error() -> void:
	var lobby := open_lobby()
	var field := find(lobby, "AddressField")
	if field != null:
		field.text = "hello"
	press(lobby, "JoinButton")
	assert_contains(text_of(lobby, "StatusLabel"), "not a valid address", "status")
	assert_eq(is_disabled(lobby, "JoinButton"), false, "join still possible")
