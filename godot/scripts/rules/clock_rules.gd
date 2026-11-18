# The clock (spec 13): 10 minutes until midnight. Pure functions: no network, no screens.
# Time left is worked out, not stored: GAME_SECONDS - seconds_played - penalty_seconds.
# First check, then change: a refused tick changes nothing and returns the reason.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const MIDNIGHT_EVENT := "Midnight! Scary Jingles is awake. The team has lost."


static func time_left(game: Dictionary) -> int:
	var left: int = Settings.GAME_SECONDS - game.get("seconds_played", 0) - game.get("penalty_seconds", 0)
	return maxi(left, 0)


# Host only, every whole second: the time runs on.
static func tick(game: Dictionary, seconds: int) -> String:
	# 1. Check ...
	if seconds < 1:
		return "Seconds must be 1 or more, got %d" % seconds
	if game.get("phase") != "hall":
		return "The game is over"
	# 2. ... then change.
	game["seconds_played"] = game.get("seconds_played", 0) + seconds
	check_midnight(game)
	return ""


# No time left while the game runs: midnight, the team has lost.
static func check_midnight(game: Dictionary) -> void:
	if game.get("phase") == "hall" and time_left(game) == 0:
		game["phase"] = "midnight"
		game["last_event"] = MIDNIGHT_EVENT


# 598 -> "09:58"
@warning_ignore("integer_division")
static func as_text(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]
