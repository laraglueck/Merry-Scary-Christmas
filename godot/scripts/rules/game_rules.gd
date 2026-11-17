# The shared game (spec 04): one Dictionary that only the host changes and then
# sends to every player. Pure functions: no network, no screens.
#
# TEAM: this is where the parts fit together. Add your data to new_game()
# (e.g. room digits, attic code, clock) and your actions to apply().
extends RefCounted

const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const LivingRoomRules = preload("res://scripts/rules/living_room_rules.gd")

static func new_game(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"phase": "hall",                            # which screen everyone sees
		"puzzle": FuseRules.create_puzzle(rng),     # fuses (spec 01)
		"living_room": LivingRoomRules.create_room(rng),
		"penalty_seconds": 0,                       # all penalties so far
		"last_event": "",                           # shown to everyone, e.g. "Player 1: wrong order, -10 s"
	}


# Host only: one player's action changes the game. Unknown actions change nothing.
static func apply(game: Dictionary, player: int, action: String, data: Dictionary) -> void:
	match action:
		"try_fuse":
			_try_fuse(game, player, data)


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
		
