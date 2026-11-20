# Tests for spec 03: network base.
# Each test uses its own port so the tests don't disturb each other.
extends "res://tests/base_test.gd"

const RoomCode = preload("res://scripts/net/room_code.gd")
const Settings = preload("res://scripts/settings.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")


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


# ---------- the clock (spec 13) ----------

func test_only_the_host_counts_the_time_and_everyone_sees_it() -> void:
	var room: Array = await make_started_room(47571)
	var before: int = room[1].game.get("seconds_played", -1)
	room[1].advance_clock(30.0)  # a player's clock does not count
	assert_eq(room[1].game.get("seconds_played", -1), before, "Player 2 does not count")
	room[0].advance_clock(61.0)
	var left: int = ClockRules.time_left(room[0].game)
	assert_true(left >= Settings.GAME_SECONDS - 64 and left <= Settings.GAME_SECONDS - 61, "host: 61 s gone, %d s left" % left)
	var same := func(): return room.all(func(net): return ClockRules.time_left(net.game) == ClockRules.time_left(room[0].game))
	assert_true(await wait_until(same), "everyone has the host's time")


func test_midnight_ends_the_game_for_everyone() -> void:
	var room: Array = await make_started_room(47572)
	room[0].advance_clock(float(Settings.GAME_SECONDS))
	var all_midnight := func(): return room.all(func(net): return net.game.get("phase") == "midnight")
	assert_true(await wait_until(all_midnight), "everyone at midnight")


# ---------- save and resume (spec 15) ----------

func saved() -> Dictionary:
	return SaveGame.load_from(SaveGame.path())


func test_the_host_saves_after_every_action() -> void:
	var room: Array = await make_started_room(47581)
	assert_eq(saved().get("penalty_seconds", -1), 0, "saved at the start")
	var wrong: Array = room[0].game["puzzle"]["fuses"][0]["order"].duplicate()
	wrong.reverse()
	room[0].send_action("try_fuse", {"wires": wrong})  # the host's own action is applied at once
	assert_eq(saved().get("penalty_seconds", -1), 10, "saved right after the action, not only at the next second")


func test_the_host_saves_the_clock() -> void:
	var room: Array = await make_started_room(47582)
	room[0].advance_clock(30.0)
	assert_true(saved().get("seconds_played", 0) >= 30, "the time is saved: %s" % saved().get("seconds_played"))


func test_midnight_deletes_the_save() -> void:
	var room: Array = await make_started_room(47583)
	room[0].advance_clock(float(Settings.GAME_SECONDS))
	assert_eq(SaveGame.exists(SaveGame.path()), false, "nothing to resume after the game")


func test_resume_brings_the_saved_game_back_to_everyone() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var old := GameRules.new_game(rng)
	old["penalty_seconds"] = 30
	old["inventory"] = ["gift_2"]
	SaveGame.save(old, SaveGame.path())
	var room: Array = await make_full_room(47584)
	assert_eq(room[0].has_saved_game(), true, "the host sees the save")
	assert_eq(room[0].can_resume(), true, "3 players and a save: can resume")
	room[0].resume_game()
	var everyone_has_it := func(): return room.all(func(net): return net.game.get("penalty_seconds") == 30 and net.game.get("inventory") == ["gift_2"])
	assert_true(await wait_until(everyone_has_it), "all three play the saved game")
	assert_eq(room[0].can_resume(), false, "not twice")


func test_no_resume_without_a_save_or_players() -> void:
	var room: Array = await make_full_room(47585)
	assert_eq(room[0].can_resume(), false, "no save")
	room[0].resume_game()
	assert_eq(room[0].game, {}, "nothing started")
	var rng := RandomNumberGenerator.new()
	SaveGame.save(GameRules.new_game(rng), SaveGame.path())
	assert_eq(room[1].can_resume(), false, "only the host resumes")


# ---------- back to the lobby (spec 17) ----------

func test_a_finished_game_ends_for_everyone_and_the_room_stays() -> void:
	var room: Array = await make_started_room(47601)
	assert_eq(room[0].can_end_game(), false, "a running game cannot be ended")
	room[0].end_game()
	assert_eq(room[0].game.is_empty(), false, "still running")
	room[0].advance_clock(float(Settings.GAME_SECONDS))
	await wait_until(func(): return room.all(func(net): return net.game.get("phase") == "midnight"))
	assert_eq(room[1].can_end_game(), false, "only the host")
	assert_eq(room[0].can_end_game(), true, "the host can end the finished game")
	room[0].end_game()
	var all_empty := func(): return room.all(func(net): return net.game.is_empty())
	assert_true(await wait_until(all_empty), "everyone's game is cleared")
	assert_eq(room[0].players.size(), 3, "all three still in the room")
	assert_eq(room[1].connected and room[2].connected, true, "still connected")
	assert_eq(room[0].can_start(), true, "a new round can start at once")



# ---------- character selection (spec 18) ----------

func pick_all(room: Array) -> void:
	var picks := [["santa", "red"], ["snowman", "green"], ["nutcracker", "yellow"]]
	for player in 3:
		room[player].send_action("pick_character", {"character": picks[player][0], "colour": picks[player][1]})
		room[player].send_action("ready", {})


func test_begin_selection_goes_to_everyone() -> void:
	var room: Array = await make_full_room(47611)
	room[0].begin_selection()
	assert_true(await wait_until(func(): return room.all(func(net): return net.game.get("phase") == "select")), "everyone is choosing")
	assert_eq(room[0].can_start(), false, "cannot start twice")
	assert_eq(room[0].can_end_game(), false, "the selection is not a finished game")


func test_begin_selection_needs_the_host_and_three_players() -> void:
	var host := make_device("Host")
	host.host_room(47612)
	host.begin_selection()
	assert_eq(host.game, {}, "one player is not enough")
	var room: Array = await make_full_room(47613)
	room[1].begin_selection()
	assert_eq(room[1].game, {}, "players cannot begin")


func test_the_clock_waits_during_the_selection() -> void:
	var room: Array = await make_full_room(47614)
	room[0].begin_selection()
	room[0].advance_clock(5.0)
	assert_eq(room[0].game.get("seconds_played"), null, "no time passes while choosing")
	assert_eq(room[0].game.get("phase"), "select", "still choosing")


func test_picks_are_decided_by_the_host_and_shared() -> void:
	var room: Array = await make_full_room(47615)
	room[0].begin_selection()
	await wait_until(func(): return room[2].game.get("phase") == "select")
	room[1].send_action("pick_character", {"character": "snowman", "colour": "green"})
	room[2].send_action("pick_character", {"character": "snowman", "colour": "yellow"})
	var settled := func(): return room.all(func(net): return net.game["selection"].has(1) and net.game["last_event"] != "")
	assert_true(await wait_until(settled), "everyone sees the result")
	assert_eq(room[0].game["selection"][1]["character"], "snowman", "Player 2 got the snowman")
	assert_eq(room[0].game["selection"].has(2), false, "Player 3 was refused")
	assert_contains(room[2].game["last_event"], "taken by Player 2", "says why")


func test_all_ready_starts_the_game_with_the_characters() -> void:
	var room: Array = await make_full_room(47616)
	room[0].begin_selection()
	await wait_until(func(): return room[2].game.get("phase") == "select")
	pick_all(room)
	assert_true(await wait_until(func(): return room.all(func(net): return net.game.get("phase") == "hall")), "the game runs at once (spec 25: the story is before the lobby)")
	assert_eq(room[2].game["characters"][1], {"character": "snowman", "colour": "green", "accessory": "none"}, "everyone knows who is who")
	assert_eq(room[0].game["seconds_played"], 0, "10:00 on the clock")


func test_a_player_who_leaves_loses_their_pick() -> void:
	var room: Array = await make_full_room(47617)
	room[0].begin_selection()
	await wait_until(func(): return room[1].game.get("phase") == "select")
	room[2].send_action("pick_character", {"character": "santa", "colour": "red"})
	await wait_until(func(): return room[0].game["selection"].has(2))
	room[2]._close()
	assert_true(await wait_until(func(): return room[0].players.size() == 2), "Player 3 left")
	assert_eq(room[0].game["selection"].has(2), false, "the pick is gone")
	assert_eq(room[0].game.get("phase"), "select", "still choosing")
