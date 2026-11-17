# The shared game (spec 04): one Dictionary that only the host changes and then
# sends to every player. Pure functions: no network, no screens.
#
# TEAM: this is where the parts fit together. Add your data to new_game()
# (e.g. room digits, attic code, clock) and your actions to apply().
extends RefCounted

const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const BathroomRules = preload("res://scripts/rules/bathroom_rules.gd")
const LivingRoomRules = preload("res://scripts/rules/living_room_rules.gd")


static func new_game(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"phase": "hall",                            # which screen everyone sees
		"puzzle": FuseRules.create_puzzle(rng),     # fuses (spec 01)
		"bathroom": BathroomRules.create(rng),      # tap lock (spec 10)
		"living_room": LivingRoomRules.create_room(rng),  # clock lock (Lara)
		"penalty_seconds": 0,                       # all penalties so far
		"last_event": "",                           # shown to everyone, e.g. "Player 1: wrong order, -10 s"
	}


# Host only: one player's action changes the game. Unknown actions change nothing.
static func apply(game: Dictionary, player: int, action: String, data: Dictionary) -> void:
	match action:
		"try_fuse":
			_try_fuse(game, player, data)
		"turn_tap":
			_turn_tap(game, player, data)
		"take_gift":
			if data.get("room") == "bathroom":
				_take_bathroom_gift(game, player)


# Player i always works on fuse i (Player 1 = red, Player 2 = green, Player 3 = gold).
static func _try_fuse(game: Dictionary, player: int, data: Dictionary) -> void:
	var wires = data.get("wires", [])
	if typeof(wires) != TYPE_ARRAY:
		wires = []
	var result := FuseRules.try_fuse(game["puzzle"], player, wires)
	var who := "Player %d" % (player + 1)
	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
	elif result["correct"]:
		var fuse: Dictionary = game["puzzle"]["fuses"][player]
		game["last_event"] = "%s turned on the %s fuse. The %s is lit!" % [who, fuse["colour"], fuse["room"]]
	else:
		game["penalty_seconds"] += result["penalty_seconds"]
		game["last_event"] = "%s: wrong order, -%d s" % [who, result["penalty_seconds"]]


# Bathroom (spec 10): one turn of a tap by any player, only once the green
# fuse is on. The team shares the turns; the fourth one tries the order.
static func _turn_tap(game: Dictionary, player: int, data: Dictionary) -> void:
	var who := "Player %d" % (player + 1)
	if "bathroom" not in FuseRules.lit_rooms(game["puzzle"]):
		game["last_event"] = "%s: the bathroom is too dark" % who
		return
	var tap = data.get("tap", "")
	var result := BathroomRules.add_turn(game["bathroom"], tap)
	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
	elif not result["tried"]:
		game["last_event"] = "%s turned the %s tap." % [who, tap]
	elif result["correct"]:
		game["last_event"] = "%s: the pipes rattle and the water drains away." % who
	else:
		game["penalty_seconds"] += result["penalty_seconds"]
		game["last_event"] = "%s: the pipes rattle angrily, -%d s" % [who, result["penalty_seconds"]]


static func _take_bathroom_gift(game: Dictionary, player: int) -> void:
	var who := "Player %d" % (player + 1)
	var result := BathroomRules.take_gift(game["bathroom"])
	if result["ok"]:
		game["last_event"] = "%s found the second present!" % who
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]
