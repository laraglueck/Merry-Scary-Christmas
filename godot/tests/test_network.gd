# Tests for spec 03: network base.
# Each test uses its own port so the tests don't disturb each other.
extends "res://tests/base_test.gd"

const RoomCode = preload("res://scripts/net/room_code.gd")
const Settings = preload("res://scripts/settings.gd")


# ---------- pure helpers ----------

func test_lan_addresses_keeps_only_wifi_ipv4() -> void:
	var all := ["127.0.0.1", "192.168.1.42", "fe80::1", "169.254.3.3", "10.0.0.7", "::1"]
	assert_eq(NetworkScript.lan_addresses(all), ["192.168.1.42", "10.0.0.7"], "addresses")


func test_next_free_index() -> void:
	assert_eq(NetworkScript.next_free_index([]), 0, "empty room")
	assert_eq(NetworkScript.next_free_index([0]), 1, "host only")
	assert_eq(NetworkScript.next_free_index([0, 2]), 1, "gap is filled")
	assert_eq(NetworkScript.next_free_index([0, 1, 2]), -1, "full")


# ---------- hosting and joining ----------

func test_host_is_player_1() -> void:
	var host := make_device("Host")
	host.host_room(47501)
	assert_eq(host.connected, true, "host connected")
	assert_eq(host.my_index, 0, "host index")
	assert_eq(host.players, [0], "players")
	assert_contains(host.status, "room open", "status")


func test_two_players_join_and_become_player_2_and_3() -> void:
	var host := make_device("Host")
	host.host_room(47502)
	var a := make_device("A")
	a.join_room("127.0.0.1", 47502)
	assert_true(await wait_until(func(): return a.connected), "A connected")
	var b := make_device("B")
	b.join_room("127.0.0.1", 47502)
	assert_true(await wait_until(func(): return b.connected), "B connected")
	assert_eq([a.my_index, b.my_index], [1, 2], "player indexes")
	var all_see_three := func(): return host.players.size() == 3 and a.players.size() == 3 and b.players.size() == 3
	assert_true(await wait_until(all_see_three), "everyone sees 3 players")
	assert_eq(a.players, [0, 1, 2], "players seen by A")
	assert_contains(b.status, "player 3", "B status")


func test_fourth_device_is_rejected() -> void:
	var host := make_device("Host")
	host.host_room(47503)
	var a := make_device("A")
	a.join_room("127.0.0.1", 47503)
	await wait_until(func(): return a.connected)
	var b := make_device("B")
	b.join_room("127.0.0.1", 47503)
	await wait_until(func(): return b.connected)
	var c := make_device("C")
	c.join_room("127.0.0.1", 47503)
	assert_true(await wait_until(func(): return "full" in c.status.to_lower()), "C sees 'room is full', status: " + c.status)
	assert_eq(c.connected, false, "C not connected")
	await wait_frames(10)
	assert_eq(host.players, [0, 1, 2], "host still has 3 players")
	assert_eq(a.players, [0, 1, 2], "A still sees 3 players")


func test_invalid_address_is_rejected() -> void:
	var a := make_device("A")
	a.join_room("hello", 47504)
	assert_contains(a.status, "not a valid address", "status")
	assert_eq(a.connected, false, "not connected")


func test_join_without_host_fails_after_timeout() -> void:
	var a := make_device("A")
	a.join_room("127.0.0.1", 47505, 0.5)
	assert_true(await wait_until(func(): return "could not connect" in a.status.to_lower()), "status: " + a.status)
	assert_eq(a.connected, false, "not connected")


# ---------- the shared counter ----------

func test_counter_is_shared_and_decided_by_host() -> void:
	var host := make_device("Host")
	host.host_room(47506)
	var a := make_device("A")
	a.join_room("127.0.0.1", 47506)
	await wait_until(func(): return a.connected)
	a.add_one()
	assert_true(await wait_until(func(): return host.counter == 1 and a.counter == 1), "both show 1 after A clicks")
	host.add_one()
	assert_true(await wait_until(func(): return host.counter == 2 and a.counter == 2), "both show 2 after host clicks")


func test_counter_does_nothing_when_not_in_a_room() -> void:
	var lonely := make_device("Lonely")
	lonely.add_one()
	assert_eq(lonely.counter, 0, "counter")


# ---------- leaving ----------

func test_players_see_when_host_leaves() -> void:
	var host := make_device("Host")
	host.host_room(47507)
	var a := make_device("A")
	a.join_room("127.0.0.1", 47507)
	await wait_until(func(): return a.connected)
	host.get_parent().free()  # the host's device is gone
	assert_true(await wait_until(func(): return "host left" in a.status.to_lower()), "status: " + a.status)
	assert_eq(a.connected, false, "A not connected any more")


# ---------- room code (spec 03b) ----------

func test_host_gets_a_room_code() -> void:
	var host := make_device("Host")
	host.host_room(47511)
	assert_true(RoomCode.is_valid_code(host.room_code), "valid code: '%s'" % host.room_code)
	assert_contains(host.status, host.room_code, "code shown in status")


func test_join_by_room_code() -> void:
	var host := make_device("Host")
	host.host_room(47512)
	var a := make_device("A")
	a.join(host.room_code)
	assert_true(await wait_until(func(): return a.connected), "A connected with the code, status: " + a.status)
	assert_eq(a.my_index, 1, "A is Player 2")


func test_join_by_code_in_lower_case_with_spaces() -> void:
	var host := make_device("Host")
	host.host_room(47513)
	var a := make_device("A")
	a.join("  " + host.room_code.to_lower() + " ")
	assert_true(await wait_until(func(): return a.connected), "A connected, status: " + a.status)


func test_two_players_join_by_code_one_after_another() -> void:
	var host := make_device("Host")
	host.host_room(47514)
	var a := make_device("A")
	a.join(host.room_code)
	await wait_until(func(): return a.connected)
	var b := make_device("B")
	b.join(host.room_code)
	assert_true(await wait_until(func(): return b.connected), "B connected, status: " + b.status)
	assert_eq([a.my_index, b.my_index], [1, 2], "player indexes")


func test_unknown_room_code_is_not_found() -> void:
	var a := make_device("A")
	a.join("ZZZZ", Settings.NETWORK_PORT, 0.5)
	assert_true(await wait_until(func(): return "not found" in a.status.to_lower()), "status: " + a.status)
	assert_eq(a.connected, false, "not connected")
	assert_eq(a.is_active(), false, "not searching any more")


func test_join_by_address_still_works() -> void:
	var host := make_device("Host")
	host.host_room(47516)
	var a := make_device("A")
	a.join("127.0.0.1", 47516)
	assert_true(await wait_until(func(): return a.connected), "A connected with the address")


func test_invalid_input_is_rejected() -> void:
	var a := make_device("A")
	a.join("hello!")
	assert_contains(a.status, "not a valid room code or address", "status")
	assert_eq(a.is_active(), false, "not searching")


func test_code_is_gone_when_host_leaves() -> void:
	var host := make_device("Host")
	host.host_room(47518)
	var code: String = host.room_code
	host.get_parent().free()
	await wait_frames(5)
	var a := make_device("A")
	a.join(code, Settings.NETWORK_PORT, 0.5)
	assert_true(await wait_until(func(): return "not found" in a.status.to_lower()), "status: " + a.status)


func test_room_with_other_code_is_ignored() -> void:
	var host := make_device("Host")
	host.host_room(47519)
	var other_code := "ZZZZ" if host.room_code != "ZZZZ" else "YYYY"
	var a := make_device("A")
	a.join(other_code, Settings.NETWORK_PORT, 0.5)
	assert_true(await wait_until(func(): return "not found" in a.status.to_lower()), "status: " + a.status)
	assert_eq(a.connected, false, "did not join the wrong room")


# ---------- the shared game (spec 04) ----------

func test_start_needs_host_and_three_players() -> void:
	var host := make_device("Host")
	host.host_room(47521)
	var a := make_device("A")
	a.join_room("127.0.0.1", 47521)
	await wait_until(func(): return a.connected)
	assert_eq(host.can_start(), false, "2 players: cannot start")
	host.start_game()
	assert_eq(host.game, {}, "no game with 2 players")
	var b := make_device("B")
	b.join_room("127.0.0.1", 47521)
	await wait_until(func(): return host.players.size() == 3)
	assert_eq(host.can_start(), true, "3 players: host can start")
	assert_eq(a.can_start(), false, "players cannot start")


func test_start_game_sends_the_same_game_to_everyone() -> void:
	var room: Array = await make_full_room(47522)
	room[0].start_game()
	assert_true(await wait_until(func(): return not room[1].game.is_empty() and not room[2].game.is_empty()), "players got the game")
	assert_eq(room[1].game, room[0].game, "A has the host's game")
	assert_eq(room[2].game.get("phase"), "hall", "phase")
	assert_eq(room[0].can_start(), false, "cannot start twice")


func test_player_action_is_decided_by_host_and_shared() -> void:
	var room: Array = await make_started_room(47523)
	var b = room[2]
	b.send_action("try_fuse", {"wires": b.game["puzzle"]["fuses"][2]["order"].duplicate()})
	var all_see_gold_on := func(): return room.all(func(net): return net.game["puzzle"]["fuses"][2]["solved"])
	assert_true(await wait_until(all_see_gold_on), "everyone sees the gold fuse on")
	assert_contains(room[0].game.get("last_event", ""), "Player 3", "event names Player 3")


func test_wrong_try_costs_penalty_for_everyone() -> void:
	var room: Array = await make_started_room(47524)
	var wrong: Array = room[1].game["puzzle"]["fuses"][1]["order"].duplicate()
	wrong.reverse()
	room[1].send_action("try_fuse", {"wires": wrong})
	assert_true(await wait_until(func(): return room.all(func(net): return net.game["penalty_seconds"] == 10)), "everyone sees 10 s")


func test_actions_before_start_do_nothing() -> void:
	var room: Array = await make_full_room(47525)
	room[1].send_action("try_fuse", {"wires": ["blue", "yellow", "white", "black"]})
	await wait_frames(10)
	assert_eq(room[0].game, {}, "host has no game")


func test_game_ends_for_others_when_host_leaves() -> void:
	var room: Array = await make_started_room(47526)
	var a = room[1]
	assert_eq(a.game.is_empty(), false, "A had a game")
	room[0].get_parent().free()
	assert_true(await wait_until(func(): return a.game.is_empty()), "A's game is gone")
	assert_contains(a.status, "host left", "status")
