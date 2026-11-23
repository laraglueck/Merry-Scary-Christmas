# The results card on the end screen (spec 34): how the game went, as lines of text.
# Pure functions: no network, no screens.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const PowerRules = preload("res://scripts/rules/power_rules.gd")


static func lines(game: Dictionary) -> Array:
	var result := []
	result.append("Time left: %s" % ClockRules.as_text(maxi(0, ClockRules.time_left(game))))
	var mistakes: int = game.get("mistakes", 0)
	if mistakes > 0:
		result.append("Mistakes: %d (-%d s)" % [mistakes, game.get("mistake_seconds", 0)])
	else:
		result.append("Mistakes: none")
	var powers := []
	for player in game.get("powers_used", []):
		var name := PowerRules.power_name(game, int(player))
		powers.append("%s (Player %d)" % [name if name != "" else "Power", int(player) + 1])
	result.append("Powers: %s" % (", ".join(powers) if not powers.is_empty() else "none"))
	var inventory: Array = game.get("inventory", [])
	if inventory.is_empty():
		result.append("Nothing found")
	var found_by: Dictionary = game.get("found_by", {})
	for item in inventory:
		var info := InventoryRules.item_info(item)
		var who = found_by.get(item, null)
		result.append("%s: %s" % [info.get("name", item), "Player %d" % (int(who) + 1) if who != null else "the team"])
	return result
