# Tests for spec 13: the clock until midnight (pure functions). The length is
# Settings.GAME_SECONDS (20 minutes since the second test round), so the tests count from it.
extends "res://tests/base_test.gd"

const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const Settings = preload("res://scripts/settings.gd")
const FULL := Settings.GAME_SECONDS


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func wrong_order(game: Dictionary, player: int) -> Array:
	var order: Array = game["puzzle"]["fuses"][player]["order"].duplicate()
	order.reverse()  # 4 different colours: reversed is never the right order
	return order


func test_a_new_game_has_the_full_time() -> void:
	var game := new_game()
	assert_eq(game.get("seconds_played"), 0, "no time played yet")
	assert_eq(ClockRules.time_left(game), FULL, "the full time")


func test_a_tick_takes_seconds_off() -> void:
	var game := new_game()
	assert_eq(ClockRules.tick(game, 1), "", "accepted")
	assert_eq(ClockRules.time_left(game), FULL - 1, "one second gone")
	ClockRules.tick(game, 59)
	assert_eq(ClockRules.time_left(game), FULL - 60, "one minute gone")
	assert_eq(game["seconds_played"], 60, "counted in seconds_played")


func test_penalties_take_time_off_the_clock() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "try_fuse", {"wires": wrong_order(game, 0)})
	assert_eq(ClockRules.time_left(game), FULL - 10, "wrong fuse: 10 s off")
	ClockRules.tick(game, 30)
	assert_eq(ClockRules.time_left(game), FULL - 40, "time and penalty together")


func test_wrong_ticks_are_refused_and_change_nothing() -> void:
	var game := new_game()
	assert_true(ClockRules.tick(game, 0) != "", "0 seconds refused")
	assert_true(ClockRules.tick(game, -5) != "", "negative seconds refused")
	assert_eq(game["seconds_played"], 0, "nothing changed")


func test_time_left_never_goes_below_zero() -> void:
	var game := new_game()
	game["penalty_seconds"] = FULL + 100
	assert_eq(ClockRules.time_left(game), 0, "not negative")


func test_midnight_ends_the_game() -> void:
	var game := new_game()
	ClockRules.tick(game, FULL - 1)
	assert_eq(game["phase"], "hall", "one second before midnight the game runs")
	ClockRules.tick(game, 1)
	assert_eq(ClockRules.time_left(game), 0, "no time left")
	assert_eq(game["phase"], "midnight", "the game is lost")
	assert_contains(game["last_event"], "Midnight", "everyone is told")


func test_a_penalty_can_strike_midnight() -> void:
	var game := new_game()
	ClockRules.tick(game, FULL - 5)
	GameRules.apply(game, 0, "try_fuse", {"wires": wrong_order(game, 0)})
	assert_eq(game["phase"], "midnight", "the penalty used up the last 5 s")


func test_after_midnight_nothing_changes() -> void:
	var game := new_game()
	game["puzzle"]["fuses"][1]["solved"] = true  # the bathroom is lit
	ClockRules.tick(game, FULL)
	assert_true(ClockRules.tick(game, 1) != "", "the clock is stopped")
	assert_eq(game["seconds_played"], FULL, "no more time counted")
	GameRules.apply(game, 0, "try_fuse", {"wires": game["puzzle"]["fuses"][0]["order"].duplicate()})
	assert_eq(game["puzzle"]["fuses"][0]["solved"], false, "no more fuses")
	GameRules.apply(game, 1, "go_to", {"place": "bathroom"})
	assert_eq(game["location"], "hall", "no more walking")
	assert_contains(game["last_event"], "Midnight", "the midnight message stays")


func test_clock_text() -> void:
	assert_eq(ClockRules.as_text(600), "10:00", "10 minutes")
	assert_eq(ClockRules.as_text(598), "09:58", "with leading zero")
	assert_eq(ClockRules.as_text(61), "01:01", "one minute one second")
	assert_eq(ClockRules.as_text(59), "00:59", "last minute")
	assert_eq(ClockRules.as_text(0), "00:00", "midnight")
