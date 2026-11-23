extends "res://tests/base_test.gd"
const GameRules = preload("res://scripts/rules/game_rules.gd")


# Directly checks the host's action handler, not a network packet.
func test_unknown_sender_cannot_change_the_game() -> void:
	var host := make_device("Host")
	host.play_alone()
	host.start_game()
	host.set_process(false)

	var before: Dictionary = host.game.duplicate(true)
	var updates := [0]
	host.game_changed.connect(func(): updates[0] += 1)

	host._host_apply(999999, "pause", {})

	assert_eq(host.game, before, "unknown sender cannot change the game")
	assert_eq(updates[0], 0, "no game update for rejected sender")


# Sends a real client request containing false identity fields.
func test_client_identity_fields_do_not_override_connection() -> void:
	var room: Array = await make_started_room(47861)
	var host = room[0]
	var client = room[1]
	host.set_process(false)

	var own_order: Array = client.game["puzzle"]["fuses"][1]["order"].duplicate()
	client.send_action("try_fuse", {
		"wires": own_order,
		"player": 0,
		"player_index": 0,
		"my_index": 0,
	})

	var solved := await wait_until(
		func(): return host.game["puzzle"]["fuses"][1]["solved"]
	)
	assert_true(solved, "request applies to the client's own fuse")
	assert_eq(host.game["puzzle"]["fuses"][0]["solved"], false, "host fuse unchanged")
	assert_contains(host.game["last_event"], "Player 2", "identity comes from connection")
func security_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func test_unknown_action_does_not_change_game() -> void:
	var game := security_game()
	var before: Dictionary = game.duplicate(true)

	GameRules.apply(game, 0, "invent_a_present", {"item": "gift_1"})

	assert_eq(game, before, "unknown action changes nothing")


func test_invalid_movement_types_do_not_change_game() -> void:
	var invalid_inputs := [
		{"dx": "left", "dy": 0},
		{"dx": 0, "dy": []},
		{"dx": null, "dy": 1},
		{"dx": true, "dy": 0},
	]

	for data in invalid_inputs:
		var game := security_game()
		var before: Dictionary = game.duplicate(true)

		GameRules.apply(game, 0, "move", data)

		assert_eq(game, before, "invalid movement changes nothing: %s" % data)


func test_invalid_clock_types_do_not_change_puzzle() -> void:
	var invalid_inputs := [
		{"hour": "3", "minute": 15},
		{"hour": 3, "minute": [15]},
		{"hour": null, "minute": 15},
		{"hour": true, "minute": 15},
	]

	for data in invalid_inputs:
		var game := security_game()
		game["location"] = "living_room"
		game["puzzle"]["fuses"][0]["solved"] = true
		var before: Dictionary = game["living_room"].duplicate(true)

		GameRules.apply(game, 0, "set_clock", data)

		assert_eq(game["living_room"], before, "invalid clock input leaves puzzle unchanged")
		assert_eq(game["penalty_seconds"], 0, "invalid types cause no penalty")
		assert_contains(game["last_event"], "whole numbers", "input error explained")