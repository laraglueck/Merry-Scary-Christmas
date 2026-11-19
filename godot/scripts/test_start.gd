# Test start (for testing only): a game started with the word "test" after "--" skips
# the fuse box and has more time, so the rooms can be tried quickly with three windows:
#   godot --path godot -- test
# Without the word nothing changes, so players never see it.
# Pure functions: no network, no screens. network.gd calls apply_if_asked when the host
# creates the game.
extends RefCounted

const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const Settings = preload("res://scripts/settings.gd")

const WORD := "test"
const TEST_SECONDS := 30 * 60  # 30 minutes instead of Settings.GAME_SECONDS


static func is_asked(args: PackedStringArray) -> bool:
	return WORD in args


static func apply_if_asked(game: Dictionary, args: PackedStringArray) -> void:
	if is_asked(args):
		apply(game)


# All three fuses on (every room and the stairs open) and 30 minutes on the clock.
# The clock counts time_left = GAME_SECONDS - seconds_played - penalties, so the extra
# time is a head start below zero (spec 13 stays as it is).
static func apply(game: Dictionary) -> void:
	for i in Settings.FUSES.size():
		var order: Array = game["puzzle"]["fuses"][i]["order"].duplicate()
		FuseRules.try_fuse(game["puzzle"], i, order)
	game["seconds_played"] = Settings.GAME_SECONDS - TEST_SECONDS
	game["last_event"] = "Test start: all fuses are on, 30 minutes until midnight."
