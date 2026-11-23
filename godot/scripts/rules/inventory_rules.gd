# The inventory (spec 14): what the whole team carries. Pure functions: no network, no screens.
# game["inventory"] holds item ids (Settings.ITEMS) in the order they were found.
# First check, then change: a refused add changes nothing and returns the reason.
#
# TEAM: when your room gives the team something, call InventoryRules.add(game, "gift_1").
extends RefCounted

const Settings = preload("res://scripts/settings.gd")


# player: who found it (for the results card, spec 34); -1 = nobody in particular.
static func add(game: Dictionary, item: String, player := -1) -> String:
	# 1. Check ...
	var info := item_info(item)
	if info.is_empty():
		return "Unknown item: %s" % item
	if has(game, item):
		return "The team already has the %s" % info["name"].to_lower()
	# 2. ... then change.
	game["inventory"].append(item)
	if player >= 0:
		if not game.has("found_by"):
			game["found_by"] = {}
		game["found_by"][item] = player
	return ""


static func has(game: Dictionary, item: String) -> bool:
	return item in game.get("inventory", [])


# The item's id, name and picture from Settings.ITEMS, or {} for an unknown item.
static func item_info(item: String) -> Dictionary:
	for info in Settings.ITEMS:
		if info["id"] == item:
			return info
	return {}
