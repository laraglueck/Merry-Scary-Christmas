# Hero powers (second test round): every hero has one power, usable once per game.
#   Santa      "Ho ho hint": a tip for the room the team is in
#   Snowman    "Freeze":     the clock gains 30 seconds
#   Nutcracker "Crack":      one part of the answer of the room the team is in
# Pure functions: no screens, no network. First check, then change; a refused use
# changes nothing and returns the reason.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")

# Santa's tips: a nudge, not the answer (the answer is the nutcracker's power).
# Which tip depends on where the team is and what is still unsolved: see hint_for().
const HINTS := {
	"fuses": "Each of you sees the order for someone else's fuse. Read it out to each other!",
	"fuses_alone": "The doll on the stairs keeps an eye on something. Have a closer look.",
	"living_room": "The clock lost its hands. The advent calendar in the bedroom knows where they belong.",
	"living_room_done": "The note under the candle is not for this room. It rhymes about warm and cold...",
	"bathroom": "The note under the candle in the living room is a rhyme about warm and cold.",
	"bathroom_done": "Those symbols in the mirror... a chest in the bedroom has symbols too. Mirrors turn things round.",
	"bedroom_before_taps": "The chest wants three symbols. The steam in the bathroom will show them, once the taps are right.",
	"bedroom": "The steamed mirror in the bathroom shows the chest's symbols... the wrong way round.",
	"bedroom_done": "Have you looked behind every calendar door? Something torn might be hiding there.",
	"attic": "Red from the living room, green from the bathroom, gold from the bedroom.",
	"attic_key": "The key lies on the floor right next to his armchair. Quietly...",
	"attic_choice": "Before you lock him in: did you put the torn photo together? And the cookies on the table downstairs... nobody ever came for them.",
}


# The hero a player chose, or "" (a saved game has text keys, a running one numbers).
static func hero_of(game: Dictionary, player: int) -> String:
	var characters: Dictionary = game.get("characters", {})
	var choice = characters.get(player, characters.get(str(player), {}))
	return str(choice.get("character", "")) if choice is Dictionary else ""


static func power_of(game: Dictionary, player: int) -> String:
	for info in Settings.CHARACTERS:
		if info["id"] == hero_of(game, player):
			return info["power"]
	return ""


static func power_name(game: Dictionary, player: int) -> String:
	for info in Settings.CHARACTERS:
		if info["id"] == hero_of(game, player):
			return info["power_name"]
	return ""


static func is_used(game: Dictionary, player: int) -> bool:
	return player in game.get("powers_used", []) or str(player) in game.get("powers_used", [])


# Uses the player's power. Returns "" or the reason it was refused.
static func use(game: Dictionary, player: int) -> String:
	# 1. Check ...
	var power := power_of(game, player)
	if power == "":
		return "Choose a hero first."
	if is_used(game, player):
		return "Your %s is already used up." % power_name(game, player)
	# 2. ... then change.
	var who := "Player %d" % (player + 1)
	var text := ""
	match power:
		"hint":
			text = _hint(game)
		"freeze":
			game["penalty_seconds"] = game.get("penalty_seconds", 0) - Settings.FREEZE_SECONDS
			text = "The clock freezes for a moment: +%d seconds." % Settings.FREEZE_SECONDS
		"crack":
			text = _crack(game, player)
	if not game.has("powers_used"):
		game["powers_used"] = []
	game["powers_used"].append(player)
	game["last_event"] = "%s used %s! %s" % [who, power_name(game, player), text]
	return ""


static func _hint(game: Dictionary) -> String:
	return hint_for(game)


# The tip for where the team is now and what is still unsolved.
static func hint_for(game: Dictionary) -> String:
	var place := str(game.get("location", "hall"))
	var solved := func(room: String) -> bool: return game.get(room, {}).get("solved", false)
	match place:
		"living_room", "bathroom":
			return HINTS[place + "_done"] if solved.call(place) else HINTS[place]
		"bedroom":
			if solved.call("bedroom"):
				return HINTS["bedroom_done"]
			return HINTS["bedroom"] if solved.call("bathroom") else HINTS["bedroom_before_taps"]
		"attic":
			var attic: Dictionary = game.get("attic", {})
			if not attic.get("unlocked", false):
				return HINTS["attic"]
			return HINTS["attic_choice"] if attic.get("key_taken", false) else HINTS["attic_key"]
	# The hall: first the fuses, then the first room still to solve.
	if FuseRules.lit_rooms(game["puzzle"]).size() < Settings.FUSES.size():
		return HINTS["fuses_alone"] if game.get("solo", false) else HINTS["fuses"]
	for room in ["living_room", "bathroom", "bedroom"]:
		if not solved.call(room):
			return "Every room is lit. Start with the %s: %s" % [room.replace("_", " "), HINTS[room].to_lower()]
	return HINTS["attic"]


# One part of the room's answer, as words.
static func _crack(game: Dictionary, player: int) -> String:
	match str(game.get("location", "hall")):
		"living_room":
			return "The short hand points to %d." % game["living_room"]["hour"]
		"bathroom":
			var first: String = game["bathroom"]["tap_order"][0]
			return "The first turn is %s." % ("warm" if first == "hot" else first)
		"bedroom":
			return "The first wheel shows the %s." % game["bedroom"]["wheels"][0]
		"attic":
			return "The red dial is %d." % AtticRules.code(game)[0]
	var fuse := 0 if game.get("solo", false) else clampi(player, 0, Settings.FUSES.size() - 1)
	return "The first wire of your fuse is %s." % game["puzzle"]["fuses"][fuse]["order"][0]
