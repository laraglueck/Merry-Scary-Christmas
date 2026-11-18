extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func make_game(lit: bool = true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var game := GameRules.new_game(rng)

	if lit:
		var wires: Array = game["puzzle"]["fuses"][0]["order"].duplicate()
		GameRules.apply(game, 0, "try_fuse", {"wires": wires})
		GameRules.apply(game, 0, "go_to", {"place": "living_room"})

	return game


func test_correct_clock_action_solves_room() -> void:
	var game := make_game()
	var room: Dictionary = game["living_room"]

	GameRules.apply(game, 0, "set_clock", {
		"hour": room["hour"],
		"minute": room["minute"],
	})

	assert_eq(room["solved"], true, "clock solved")
	assert_eq(game["penalty_seconds"], 0, "no penalty")


func test_wrong_clock_action_costs_twenty_seconds() -> void:
	var game := make_game()
	var room: Dictionary = game["living_room"]
	var before := room.duplicate(true)
	var wrong_hour: int = room["hour"] % 12 + 1

	GameRules.apply(game, 0, "set_clock", {
		"hour": wrong_hour,
		"minute": room["minute"],
	})

	assert_eq(game["penalty_seconds"], 20, "one penalty")
	assert_eq(room, before, "room unchanged")


func test_clock_action_is_refused_when_room_is_dark() -> void:
	var game := make_game(false)
	var room: Dictionary = game["living_room"]
	var before := room.duplicate(true)

	GameRules.apply(game, 0, "set_clock", {
		"hour": room["hour"],
		"minute": room["minute"],
	})

	assert_eq(room, before, "room unchanged")
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "dark", "reason given")


func test_gift_action_adds_first_present_only_once() -> void:
	var game := make_game()
	var room: Dictionary = game["living_room"]

	GameRules.apply(game, 0, "set_clock", {
		"hour": room["hour"],
		"minute": room["minute"],
	})
	GameRules.apply(game, 0, "take_gift", {"room": "living_room"})

	assert_eq(room["gift_taken"], true, "gift taken")
	assert_eq(game["inventory"], ["gift_1"], "first present")

	GameRules.apply(game, 1, "take_gift", {"room": "living_room"})
	assert_eq(game["inventory"], ["gift_1"], "no duplicate")


func test_gift_action_is_refused_before_solving() -> void:
	var game := make_game()
	game["last_event"] = ""

	GameRules.apply(game, 0, "take_gift", {"room": "living_room"})

	assert_eq(game["living_room"]["gift_taken"], false, "gift remains")
	assert_eq(game["inventory"], [], "inventory unchanged")
	assert_true(game["last_event"] != "", "feedback given")
	
func test_clock_action_requires_team_in_living_room() -> void:
	var game := make_game()
	GameRules.apply(game, 0, "go_to", {"place": "hall"})
	game["last_event"] = ""

	var room: Dictionary = game["living_room"]
	var before := room.duplicate(true)

	GameRules.apply(game, 0, "set_clock", {
		"hour": room["hour"],
		"minute": room["minute"],
	})

	assert_eq(room, before, "room unchanged")
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_true(game["last_event"] != "", "reason given")


func test_clock_action_rejects_missing_or_invalid_numbers() -> void:
	for data in [
		{},
		{"hour": 3},
		{"minute": 8},
		{"hour": "3", "minute": 8},
		{"hour": 3, "minute": "8"},
		{"hour": 3.5, "minute": 8},
		{"hour": 3, "minute": true},
	]:
		var game := make_game()
		game["last_event"] = ""
		var before: Dictionary = game["living_room"].duplicate(true)

		GameRules.apply(game, 0, "set_clock", data)

		assert_eq(game["living_room"], before, "room unchanged")
		assert_eq(game["penalty_seconds"], 0, "no penalty")
		assert_true(game["last_event"] != "", "reason given")


func test_gift_action_is_refused_in_dark_room() -> void:
	var game := make_game(false)

	# Even a solved clock must not bypass the light check.
	game["living_room"]["solved"] = true
	var before: Dictionary = game["living_room"].duplicate(true)
	game["last_event"] = ""

	GameRules.apply(game, 0, "take_gift", {"room": "living_room"})

	assert_eq(game["living_room"], before, "room unchanged")
	assert_eq(game["inventory"], [], "inventory unchanged")
	assert_contains(game["last_event"], "dark", "reason given")
	
func test_wrong_clock_setting_can_trigger_midnight() -> void:
	var game := make_game()
	game["seconds_played"] = Settings.GAME_SECONDS - 10

	var room: Dictionary = game["living_room"]
	var wrong_hour: int = room["hour"] % 12 + 1

	GameRules.apply(game, 0, "set_clock", {
		"hour": wrong_hour,
		"minute": room["minute"],
	})

	assert_eq(
		game["penalty_seconds"],
		Settings.LIVING_ROOM_PENALTY_SECONDS,
		"one clock penalty"
	)
	assert_eq(ClockRules.time_left(game), 0, "time never below zero")
	assert_eq(game["phase"], "midnight", "midnight ends game")
	assert_eq(
		game["last_event"],
		ClockRules.MIDNIGHT_EVENT,
		"midnight message"
	)
	assert_eq(room["solved"], false, "wrong answer stays unsolved")


func test_living_room_actions_change_nothing_after_midnight() -> void:
	var game := make_game()
	ClockRules.tick(game, Settings.GAME_SECONDS)
	var before := game.duplicate(true)

	GameRules.apply(game, 0, "set_clock", {
		"hour": game["living_room"]["hour"],
		"minute": game["living_room"]["minute"],
	})
	assert_eq(game, before, "clock action ignored after ending")

	GameRules.apply(game, 0, "take_gift", {"room": "living_room"})
	assert_eq(game, before, "gift action ignored after ending")
func test_gift_action_requires_team_in_living_room() -> void:
	var game := make_game()
	var room: Dictionary = game["living_room"]

	GameRules.apply(game, 0, "set_clock", {
		"hour": room["hour"],
		"minute": room["minute"],
	})
	assert_eq(room["solved"], true, "clock solved before leaving")

	GameRules.apply(game, 0, "go_to", {"place": "hall"})
	assert_eq(game["location"], "hall", "team left living room")
	game["last_event"] = ""

	var before := room.duplicate(true)
	GameRules.apply(game, 0, "take_gift", {"room": "living_room"})

	assert_eq(room, before, "gift remains in room")
	assert_eq(game["inventory"], [], "inventory unchanged")
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "enter the living room", "reason")
	
