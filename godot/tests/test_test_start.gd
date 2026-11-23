# Tests for the test start: a game started with the word "test" begins with all fuses
# on and 30 minutes on the clock; without the word nothing changes.
extends "res://tests/base_test.gd"

const TestStart = preload("res://scripts/test_start.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const HouseRules = preload("res://scripts/rules/house_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func test_without_the_word_nothing_changes() -> void:
	var game := new_game()
	var before := game.duplicate(true)
	TestStart.apply_if_asked(game, PackedStringArray([]))
	TestStart.apply_if_asked(game, PackedStringArray(["--resolution", "576x324"]))
	assert_eq(game, before, "a normal game stays a normal game")
	assert_eq(ClockRules.time_left(game), Settings.GAME_SECONDS, "the normal time")


func test_with_the_word_all_fuses_are_on() -> void:
	var game := new_game()
	TestStart.apply_if_asked(game, PackedStringArray(["test"]))
	assert_eq(FuseRules.lit_rooms(game["puzzle"]).size(), Settings.FUSES.size(), "every room lit")
	assert_eq(HouseRules.go_to(game, "attic"), "", "the stairs are open")


func test_with_the_word_the_clock_has_30_minutes() -> void:
	var game := new_game()
	TestStart.apply_if_asked(game, PackedStringArray(["test"]))
	assert_eq(ClockRules.time_left(game), 30 * 60, "30 minutes until midnight")
	assert_contains(game["last_event"], "Test start", "everyone sees it is a test game")
