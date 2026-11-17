# Walking through the house (spec 07). Pure functions: no network, no screens.
# The team walks together: game["location"] is where everyone is.
# First check, then change. A refused move changes nothing and returns the reason.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")


# Returns "" when the team moved, otherwise why not.
static func go_to(game: Dictionary, place: String) -> String:
	var error := _check(game, place)
	if error == "":
		game["location"] = place
	return error


# "living_room" -> "living/dining room" (the name players read).
static func place_name(place: String) -> String:
	for fuse in Settings.FUSES:
		if fuse["place"] == place:
			return fuse["room"]
	return place


# Is this room's fuse on? (The hall and the attic have no fuse of their own.)
static func is_lit(game: Dictionary, place: String) -> bool:
	var fuse_index := _fuse_for(place)
	return fuse_index != -1 and game["puzzle"]["fuses"][fuse_index]["solved"]


static func _check(game: Dictionary, place: String) -> String:
	var here: String = game.get("location", "hall")
	if place not in Settings.PLACES:
		return "Unknown place: %s" % place
	if place == here:
		return "The team is already in the %s." % place_name(place)
	if here != "hall" and place != "hall":
		return "Go back to the hall first: every room is reached from there."
	if place == "attic" and FuseRules.lit_rooms(game["puzzle"]).size() < Settings.FUSES.size():
		return "The stairs are pitch dark. Turn on all three fuses first."
	var fuse_index := _fuse_for(place)
	if fuse_index != -1 and not game["puzzle"]["fuses"][fuse_index]["solved"]:
		return "The %s is still dark. Turn on the %s fuse first." % [place_name(place), Settings.FUSES[fuse_index]["colour"]]
	return ""


static func _fuse_for(place: String) -> int:
	for i in Settings.FUSES.size():
		if Settings.FUSES[i]["place"] == place:
			return i
	return -1
