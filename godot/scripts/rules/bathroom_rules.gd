# Bathroom rules (spec 10): the tap lock, the present and the mirror clue.
# Pure functions: no scenes, no network. The screen and the host call these.
# Rule: first check, then change. Invalid input changes nothing and
# comes back as an error text (GDScript has no exceptions).
extends RefCounted

const Settings = preload("res://scripts/settings.gd")


# The bathroom part of the shared game: a secret order of four turns
# (each "hot" or "cold") and the digit for the green dial of the attic lock.
static func create(rng: RandomNumberGenerator) -> Dictionary:
	var tap_order := []
	for i in Settings.TAP_TURNS:
		tap_order.append(Settings.TAPS[rng.randi_range(0, Settings.TAPS.size() - 1)])
	return {
		"tap_order": tap_order,
		"digit": rng.randi_range(1, 9),
		"solved": false,
		"gift_taken": false,
	}


# Four turns at once, tried after the fourth turn on the screen.
static func try_taps(room: Dictionary, taps: Array) -> Dictionary:
	# 1. Check everything first ...
	var error := _check_taps(room, taps)
	if error != "":
		return {"correct": false, "penalty_seconds": 0, "error": error}

	# 2. ... then change.
	if taps == room["tap_order"]:
		room["solved"] = true
		return {"correct": true, "penalty_seconds": 0, "error": ""}
	return {"correct": false, "penalty_seconds": Settings.TAP_PENALTY_SECONDS, "error": ""}


# The present lies in the tub once the water has drained.
static func take_gift(room: Dictionary) -> Dictionary:
	if not room["solved"]:
		return {"ok": false, "error": "The taps are not solved yet"}
	if room["gift_taken"]:
		return {"ok": false, "error": "The present was already taken"}
	room["gift_taken"] = true
	return {"ok": true, "error": ""}


# The clue for the bedroom chest: its three symbols as a mirror shows them,
# in reverse order. Returns a new list; the bedroom's wheels stay as they are.
static func mirror_symbols(wheels: Array) -> Array:
	var mirrored := wheels.duplicate()
	mirrored.reverse()
	return mirrored


# Returns "" if the turns are valid, otherwise the reason.
static func _check_taps(room: Dictionary, taps: Array) -> String:
	if room["solved"]:
		return "The taps are already solved"
	if taps.size() != Settings.TAP_TURNS:
		return "Expected %d turns, got %d" % [Settings.TAP_TURNS, taps.size()]
	for tap in taps:
		if tap not in Settings.TAPS:
			return "Unknown turn: %s" % tap
	return ""
