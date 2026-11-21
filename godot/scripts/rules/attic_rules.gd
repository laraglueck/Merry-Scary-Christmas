# Attic rules (spec 16): the code lock with three dials and the final choice.
# Pure functions: no scenes, no network. The screen and the host call these.
# Rule: first check, then change. Invalid input changes nothing and
# comes back as an error text (GDScript has no exceptions).
extends RefCounted

const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")

const Settings = preload("res://scripts/settings.gd")

const CHOICES := {"lock_in": "scary", "reconcile": "merry"}  # choice -> ending
const NO_PHOTO := "You have nothing that could change his mind."
const NO_COOKIES := "The photo alone feels too little. Remember the cookies on the table downstairs?"  # spec 31


# The attic part of the shared game. The code is not stored here: it is the
# three room digits, see code().
static func create() -> Dictionary:
	return {"unlocked": false, "key_taken": false, "choice": ""}


# The digits the lock wants, in dial order red, green, gold. Until the bedroom
# exists, the gold digit is 0: "not checked yet", any gold digit counts.
static func code(game: Dictionary) -> Array:
	var bedroom: Dictionary = game.get("bedroom", {})
	return [
		game["living_room"]["digit"],
		game["bathroom"]["digit"],
		BedroomRules.gold_digit(bedroom) if bedroom.has("digit") else 0,
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


# The key on the floor beside him (spec 21): once the lock is open, and once.
static func take_key(attic: Dictionary) -> Dictionary:
	# 1. Check ...
	if not attic["unlocked"]:
		return {"ok": false, "error": "The attic is still locked."}
	if attic.get("key_taken", false):
		return {"ok": false, "error": "The key is already taken."}
	# 2. ... then change.
	attic["key_taken"] = true
	return {"ok": true, "error": ""}


# The final choice beside the sleeping Scary Jingles. Returns the ending
# ("scary" or "merry"), or "" and an error text when refused.
# The good ending needs the whole photo AND the cookies (spec 31).
static func choose(attic: Dictionary, choice: String, has_photo: bool, has_cookies: bool) -> Dictionary:
	# 1. Check ...
	if not attic["unlocked"]:
		return {"ending": "", "error": "The attic is still locked."}
	if attic["choice"] != "":
		return {"ending": "", "error": "The team has already decided."}
	if not CHOICES.has(choice):
		return {"ending": "", "error": "Unknown choice: %s" % choice}
	if choice == "reconcile" and not has_photo:
		return {"ending": "", "error": NO_PHOTO}
	if choice == "reconcile" and not has_cookies:
		return {"ending": "", "error": NO_COOKIES}
	if choice == "lock_in" and not attic.get("key_taken", false):
		return {"ending": "", "error": "Take the key first."}

	# 2. ... then change.
	attic["choice"] = choice
	return {"ending": CHOICES[choice], "error": ""}


static func _refused(error: String) -> Dictionary:
	return {"correct": false, "penalty_seconds": 0, "error": error}
