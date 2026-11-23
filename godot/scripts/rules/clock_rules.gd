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
	if game.get("paused", false):
		return "The game is paused"  # spec 26
	# 2. ... then change.
	game["seconds_played"] = game.get("seconds_played", 0) + seconds
	check_midnight(game)
	return ""


# No time left while the game runs: midnight, the team has lost.
static func check_midnight(game: Dictionary) -> void:
	if game.get("phase") == "hall" and time_left(game) == 0:
		game["phase"] = "midnight"
		game["last_event"] = MIDNIGHT_EVENT


# ---------- the last minutes (spec 35) ----------

# 0 = calm, 1 = the last 5 minutes, 2 = the last 2 minutes.
static func dread_stage(left: int) -> int:
	if left <= Settings.PANIC_SECONDS:
		return 2
	if left <= Settings.DREAD_SECONDS:
		return 1
	return 0


# The clock strikes when the time left reaches a full minute in the last five, going from
# `before` down to `now` (a penalty may jump over one: it still rings, once).
static func chime_due(before: int, now: int) -> bool:
	if now >= before:
		return false
	for minute in range(Settings.DREAD_SECONDS, 0, -60):
		if now <= minute and minute < before:
			return true
	return false


# 598 -> "09:58"
@warning_ignore("integer_division")
static func as_text(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]
