# The shared game (spec 04): one Dictionary that only the host changes and then
# sends to every player. Pure functions: no network, no screens.
#
# TEAM: this is where the parts fit together. Add your data to new_game()
# (e.g. room digits, attic code, clock) and your actions to apply().
extends RefCounted

const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const BathroomRules = preload("res://scripts/rules/bathroom_rules.gd")
const HouseRules = preload("res://scripts/rules/house_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const LivingRoomRules = preload("res://scripts/rules/living_room_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")


static func new_game(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"phase": "hall",                            # "hall" = the game runs inside the house
		"location": "hall",                         # where the whole team is (spec 07)
		"puzzle": FuseRules.create_puzzle(rng),     # fuses (spec 01)
		"bathroom": BathroomRules.create(rng),      # tap lock (spec 10)
		"living_room": LivingRoomRules.create_room(rng),  # clock lock (Lara)
		"attic": AtticRules.create(),               # code lock and the final choice (spec 16)
		"penalty_seconds": 0,                       # all penalties so far
		"inventory": [],                            # what the team carries (spec 14), e.g. ["gift_2"]
		"seconds_played": 0,                        # the clock (spec 13): time left = 600 - this - penalties
		"last_event": "",                           # shown to everyone, e.g. "Player 1: wrong order, -10 s"
	}


# Host only: one player's action changes the game. Unknown actions change nothing.
# After midnight (or another end) nothing changes any more (spec 13).
static func apply(game: Dictionary, player: int, action: String, data: Dictionary) -> void:
	if game.get("phase") != "hall":
		return

	match action:
		"try_fuse":
			_try_fuse(game, player, data)
		"turn_tap":
			_turn_tap(game, player, data)
		"set_clock":
			_set_clock(game, player, data)
		"take_gift":
			if data.get("room") == "bathroom":
				_take_bathroom_gift(game, player)
			elif data.get("room") == "living_room":
				_take_living_room_gift(game, player)
		"go_to":
			_go_to(game, player, data)
		"try_attic_code":
			_try_attic_code(game, player, data)
		"choose_ending":
			_choose_ending(game, player, data)

	ClockRules.check_midnight(game)
	
	

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
		InventoryRules.add(game, "gift_2")
		game["last_event"] = "%s found the second present!" % who
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]


# Walking (spec 07): the whole team moves; a refused move only explains why.
static func _go_to(game: Dictionary, player: int, data: Dictionary) -> void:
	var who := "Player %d" % (player + 1)
	var place := str(data.get("place", ""))
	var error := HouseRules.go_to(game, place)
	if error != "":
		game["last_event"] = "%s: %s" % [who, error]
	elif place == "hall":
		game["last_event"] = "%s led the team back to the hall." % who
	elif place == "attic":
		game["last_event"] = "%s climbed the stairs to the attic." % who
	else:
		game["last_event"] = "%s opened the %s door." % [who, HouseRules.place_name(place)]
static func _can_use_living_room(game: Dictionary, player: int) -> bool:
	var who := "Player %d" % (player + 1)

	# The red fuse lights the living room.
	if not game["puzzle"]["fuses"][0]["solved"]:
		game["last_event"] = "%s: the living room is too dark" % who
		return false

	if game.get("location") != "living_room":
		game["last_event"] = "%s: enter the living room first" % who
		return false

	return true


static func _set_clock(
	game: Dictionary,
	player: int,
	data: Dictionary
) -> void:
	if not _can_use_living_room(game, player):
		return

	var who := "Player %d" % (player + 1)
	var hour = data.get("hour")
	var minute = data.get("minute")

	if typeof(hour) != TYPE_INT or typeof(minute) != TYPE_INT:
		game["last_event"] = "%s: clock positions must be whole numbers" % who
		return

	var result := LivingRoomRules.try_clock(
		game["living_room"], hour, minute
	)

	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
	elif result["correct"]:
		game["last_event"] = "%s: the clock opens!" % who
	else:
		game["penalty_seconds"] += result["penalty_seconds"]
		game["last_event"] = "%s: wrong clock setting, -%d s" % [
			who, result["penalty_seconds"]
		]


static func _take_living_room_gift(game: Dictionary, player: int) -> void:
	if not _can_use_living_room(game, player):
		return

	var who := "Player %d" % (player + 1)
	var result := LivingRoomRules.take_gift(game["living_room"])

	if result["taken"]:
		InventoryRules.add(game, "gift_1")
		game["last_event"] = "%s found the first present!" % who
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]


# Attic (spec 16): the code lock and the final choice, only with the team upstairs.
static func _in_attic(game: Dictionary, player: int) -> bool:
	if not game.has("attic"):
		game["attic"] = AtticRules.create()  # a game saved before spec 16
	if game.get("location") != "attic":
		game["last_event"] = "Player %d: climb up to the attic first" % (player + 1)
		return false
	return true


static func _try_attic_code(game: Dictionary, player: int, data: Dictionary) -> void:
	if not _in_attic(game, player):
		return
	var who := "Player %d" % (player + 1)
	var dials = data.get("dials", [])
	if typeof(dials) != TYPE_ARRAY:
		dials = []
	var result := AtticRules.try_code(game["attic"], dials, AtticRules.code(game))
	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
	elif result["correct"]:
		game["last_event"] = "%s: the attic lock clicks open." % who
	else:
		game["penalty_seconds"] += result["penalty_seconds"]
		game["last_event"] = "%s: wrong code, -%d s" % [who, result["penalty_seconds"]]


static func _choose_ending(game: Dictionary, player: int, data: Dictionary) -> void:
	if not _in_attic(game, player):
		return
	var who := "Player %d" % (player + 1)
	var choice := str(data.get("choice", ""))
	var result := AtticRules.choose(game["attic"], choice, InventoryRules.has(game, "photo"))
	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
		return
	if choice == "lock_in":
		InventoryRules.add(game, "key")
		game["last_event"] = "%s took the key and locked Scary Jingles in." % who
	else:
		game["last_event"] = "%s left the photo and the cookies beside him." % who
	game["phase"] = result["ending"]  # the game ends, like at midnight
