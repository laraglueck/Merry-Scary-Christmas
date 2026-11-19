# Character selection (spec 18). Pure functions: no network, no screens.
# `selection` maps a player index to {"character", "colour", "ready"}; it lives in
# game["selection"] while game["phase"] is "select".
# First check, then change: a refused action changes nothing and returns the reason.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")


static func character_ids() -> Array:
	return Settings.CHARACTERS.map(func(info): return info["id"])


static func colour_ids() -> Array:
	return Settings.CHARACTER_COLOURS.map(func(info): return info["id"])


static func accessory_ids() -> Array:
	return Settings.ACCESSORIES.map(func(info): return info["id"])


# The next colour in the given direction (+1 or -1); goes round. Colours can be shared
# (spec 18, change), so none is skipped.
static func next_colour(selection: Dictionary, player: int, direction: int) -> String:
	var colours := colour_ids()
	var current := colours.find(selection.get(player, {}).get("colour", colours[0]))
	return colours[posmod(current + direction, colours.size())]


# The next accessory in the given direction (+1 or -1); goes round.
static func next_accessory(current: String, direction: int) -> String:
	var accessories := accessory_ids()
	var index := accessories.find(current)
	return accessories[posmod(index + direction, accessories.size())]


# Sets (or changes) the player's character and colour. A new pick is not "ready" any more.
# Each character belongs to one player; a colour may be shared (spec 18, change).
static func pick(selection: Dictionary, player: int, character: String, colour: String, accessory := "none") -> String:
	# 1. Check ...
	if player < 0 or player >= Settings.MAX_PLAYERS:
		return "Unknown player: %d" % player
	if character not in character_ids():
		return "Unknown character: %s" % character
	if colour not in colour_ids():
		return "Unknown colour: %s" % colour
	if accessory not in accessory_ids():
		return "Unknown accessory: %s" % accessory
	var owner_of_character := owner_of(selection, "character", character, player)
	if owner_of_character != -1:
		return "The %s is taken by Player %d" % [character, owner_of_character + 1]
	# 2. ... then change.
	selection[player] = {"character": character, "colour": colour, "accessory": accessory, "ready": false}
	return ""


static func set_ready(selection: Dictionary, player: int) -> String:
	if not selection.has(player):
		return "Choose a character first"
	selection[player]["ready"] = true
	return ""


static func all_ready(selection: Dictionary) -> bool:
	if selection.size() != Settings.MAX_PLAYERS:
		return false
	return selection.values().all(func(choice): return choice["ready"])


# The player who has this character or colour (key "character" / "colour"), or -1.
# `except` is the asking player: their own choice does not count.
static func owner_of(selection: Dictionary, key: String, value: String, except := -1) -> int:
	for player in selection:
		if player != except and selection[player][key] == value:
			return player
	return -1


# The colour a player starts with: the first one nobody else has (so the start looks
# different for everyone; the arrows may still pick a shared one).
static func first_free_colour(selection: Dictionary, player: int) -> String:
	for colour in colour_ids():
		if owner_of(selection, "colour", colour, player) == -1:
			return colour
	return ""


static func picture_file(character: String, colour: String) -> String:
	return "char_%s.png" % character if colour == "red" else "char_%s_%s.png" % [character, colour]


# What the running game remembers: the choices without the "ready" flags.
static func final_characters(selection: Dictionary) -> Dictionary:
	var result := {}
	for player in selection:
		result[player] = {"character": selection[player]["character"], "colour": selection[player]["colour"],
			"accessory": selection[player]["accessory"]}
	return result


# The empty selection, as the shared game while the players choose.
static func new_selection_game() -> Dictionary:
	return {"phase": "select", "selection": {}, "last_event": ""}


# Host only: one player's action in the selection phase.
static func apply(game: Dictionary, player: int, action: String, data: Dictionary) -> void:
	var error := ""
	match action:
		"pick_character":
			error = pick(game["selection"], player, str(data.get("character", "")), str(data.get("colour", "")),
				str(data.get("accessory", "none")))
		"ready":
			error = set_ready(game["selection"], player)
		_:
			return
	game["last_event"] = "Player %d: %s" % [player + 1, error] if error != "" else ""
