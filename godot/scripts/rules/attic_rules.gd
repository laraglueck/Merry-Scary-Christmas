# Attic rules (spec 16): the code lock with three dials and the final choice.
# Pure functions: no scenes, no network. The screen and the host call these.
# Rule: first check, then change. Invalid input changes nothing and
# comes back as an error text (GDScript has no exceptions).
extends RefCounted

const Settings = preload("res://scripts/settings.gd")

const CHOICES := {"lock_in": "scary", "reconcile": "merry"}  # choice -> ending
const NO_PHOTO := "You have nothing that could change his mind."


# The attic part of the shared game. The code is not stored here: it is the
# three room digits, see code().
static func create() -> Dictionary:
	return {"unlocked": false, "choice": ""}


# The digits the lock wants, in dial order red, green, gold. Until the bedroom
# exists, the gold digit is 0: "not checked yet", any gold digit counts.
static func code(game: Dictionary) -> Array:
	return [
		game["living_room"]["digit"],
		game["bathroom"]["digit"],
		game.get("bedroom", {}).get("digit", 0),
	]


# One try at the lock with three dials (red, green, gold).
static func try_code(attic: Dictionary, dials: Array, wanted: Array) -> Dictionary:
	# 1. Check ...
	if attic["unlocked"]:
		return _refused("The attic lock is already open.")
	if dials.size() != 3:
		return _refused("The lock has three dials, got %d." % dials.size())
	for dial in dials:
		if typeof(dial) != TYPE_INT or dial < 1 or dial > 9:
			return _refused("Each dial shows a digit from 1 to 9, got %s." % str(dial))

	# 2. ... then change.
	for i in 3:
		if wanted[i] != 0 and dials[i] != wanted[i]:
			return {"correct": false, "penalty_seconds": Settings.ATTIC_PENALTY_SECONDS, "error": ""}
	attic["unlocked"] = true
	return {"correct": true, "penalty_seconds": 0, "error": ""}


# The final choice beside the sleeping Scary Jingles. Returns the ending
# ("scary" or "merry"), or "" and an error text when refused.
static func choose(attic: Dictionary, choice: String, has_photo: bool) -> Dictionary:
	# 1. Check ...
	if not attic["unlocked"]:
		return {"ending": "", "error": "The attic is still locked."}
	if attic["choice"] != "":
		return {"ending": "", "error": "The team has already decided."}
	if not CHOICES.has(choice):
		return {"ending": "", "error": "Unknown choice: %s" % choice}
	if choice == "reconcile" and not has_photo:
		return {"ending": "", "error": NO_PHOTO}

	# 2. ... then change.
	attic["choice"] = choice
	return {"ending": CHOICES[choice], "error": ""}


static func _refused(error: String) -> Dictionary:
	return {"correct": false, "penalty_seconds": 0, "error": error}
