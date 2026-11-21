# Tests for the chest hint (second test round): after Settings.RESCUE_TRIES wrong tries at the toy chest,
# the team is reminded that the mirror shows the symbols the wrong way round.
extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func game_in_the_bedroom() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var game := GameRules.new_game(rng)
	for i in 3:
		FuseRules.try_fuse(game["puzzle"], i, game["puzzle"]["fuses"][i]["order"].duplicate())
	game["location"] = "bedroom"
	return game


func wrong_symbols(game: Dictionary) -> Array:
	var symbols: Array = game["bedroom"]["wheels"].duplicate()
	symbols[0] = "star" if symbols[0] != "star" else "bell"
	return symbols


func test_no_hint_before_the_rescue() -> void:
	var game := game_in_the_bedroom()
	for i in Settings.RESCUE_TRIES - 1:
		GameRules.apply(game, 0, "set_wheels", {"symbols": wrong_symbols(game)})
		assert_true(not "mirror" in game["last_event"], "no hint after try %d" % (i + 1))


func test_the_rescue_try_hints_at_the_mirror() -> void:
	var game := game_in_the_bedroom()
	for i in Settings.RESCUE_TRIES:
		GameRules.apply(game, 0, "set_wheels", {"symbols": wrong_symbols(game)})
	assert_contains(game["last_event"], "wrong symbols", "still says it was wrong")
	assert_contains(game["last_event"], "mirror", "and hints at the mirror")
	assert_contains(game["last_event"], "wrong way round", "it is backwards")
