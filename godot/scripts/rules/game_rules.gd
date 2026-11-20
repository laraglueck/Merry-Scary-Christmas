# The shared game (spec 04): one Dictionary that only the host changes and then
# sends to every player. Pure functions: no network, no screens.
#
# TEAM: this is where the parts fit together. Add your data to new_game()
# (e.g. room digits, attic code, clock) and your actions to apply().
extends RefCounted

const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const BathroomRules = preload("res://scripts/rules/bathroom_rules.gd")
const HouseRules = preload("res://scripts/rules/house_rules.gd")
const Settings = preload("res://scripts/settings.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const LivingRoomRules = preload("res://scripts/rules/living_room_rules.gd")
const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")
const PhotoRules = preload("res://scripts/rules/photo_rules.gd")
const CharacterRules = preload("res://scripts/rules/character_rules.gd")
const WalkRules = preload("res://scripts/rules/walk_rules.gd")


static func new_game(rng: RandomNumberGenerator, characters := {}) -> Dictionary:
	return {
		"phase": "hall",                            # "hall" = the game runs inside the house
		"characters": characters,                   # who plays whom (spec 18): {player: {character, colour}}
		"location": "hall",                         # where the whole team is (spec 07)
		"figures": WalkRules.new_figures(),         # where each figure stands and walks to (spec 19)
		"puzzle": FuseRules.create_puzzle(rng),     # fuses (spec 01)
		"bathroom": BathroomRules.create(rng),      # tap lock (spec 10)
		"living_room": LivingRoomRules.create_room(rng),  # clock lock (Lara)
		"bedroom": BedroomRules.create_room(rng),
		"attic": AtticRules.create(),               # code lock and the final choice (spec 16)
		"penalty_seconds": 0,                       # all penalties so far
		"inventory": [],                            # what the team carries (spec 14), e.g. ["gift_2"]
		"seconds_played": 0,                        # the clock (spec 13): time left = 600 - this - penalties
		"last_event": "",                           # shown to everyone, e.g. "Player 1: wrong order, -10 s"
		"paused": false,                            # spec 26: the clock and everything else wait
		"paused_by": -1,                            # who paused (player index), -1 if nobody
	}


# Spec 26: the game waits for everyone; the figures stop where they are.
static func _pause(game: Dictionary, player: int) -> void:
	game["paused"] = true
	game["paused_by"] = player
	game["last_event"] = "Player %d paused the game" % (player + 1)
	for figure in game.get("figures", {}).values():
		figure["dx"] = 0.0
		figure["dy"] = 0.0


# Host only: one player's action changes the game. Unknown actions change nothing.
# After midnight (or another end) nothing changes any more (spec 13).
static func apply(game: Dictionary, player: int, action: String, data: Dictionary) -> void:
	if game.get("phase") == "select":  # before the game: the characters are chosen (spec 18)
		CharacterRules.apply(game, player, action, data)
		return
	if game.get("phase") != "hall":
		return
	# Pause (spec 26): anyone pauses for everyone, anyone continues; while paused nothing else happens.
	if action == "pause":
		_pause(game, player)
		return
	if action == "resume":
		game["paused"] = false
		game["paused_by"] = -1
		game["last_event"] = ""
		return
	if game.get("paused", false):
		return

	match action:
		"try_fuse":
			_try_fuse(game, player, data)
		"turn_tap":
			_turn_tap(game, player, data)
		"set_clock":
			_set_clock(game, player, data)
		"set_wheels":
			_set_wheels(game, player, data)
		"take_photo":
			_take_bedroom_photo(game, player)
		"take_gift":
			if data.get("room") == "bathroom":
				_take_bathroom_gift(game, player)
			elif data.get("room") == "living_room":
				_take_living_room_gift(game, player)
			elif data.get("room") == "bedroom":
				_take_bedroom_gift(game, player)
		"go_to":
			_go_to(game, player, data)
		"move":
			var dx = data.get("dx", null)
			var dy = data.get("dy", null)
			if typeof(dx) in [TYPE_FLOAT, TYPE_INT] and typeof(dy) in [TYPE_FLOAT, TYPE_INT]:
				WalkRules.set_direction(game, player, float(dx), float(dy))
		"try_attic_code":
			_try_attic_code(game, player, data)
		"choose_ending":
			_choose_ending(game, player, data)
		"take_key":
			_take_key(game, player)
		"take_piece":
			_take_piece(game, player, data)
		"assemble_photo":
			_assemble_photo(game, player, data)

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
		game["last_event"] = "%s turned the %s tap." % [who, "warm" if tap == "hot" else tap]  # the rhyme says warm
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
		game["last_event"] = "%s locked Scary Jingles in." % who
	else:
		game["last_event"] = "%s left the photo and the cookies beside him." % who
	game["phase"] = result["ending"]  # the game ends, like at midnight


# Bedroom: check the three symbols on the toy chest.
static func _set_wheels(game: Dictionary, player: int, data: Dictionary) -> void:
	var who := "Player %d" % (player + 1)

	if game.get("location") != "bedroom":
		game["last_event"] = "%s: enter the bedroom first" % who
		return

	if "bedroom" not in FuseRules.lit_rooms(game["puzzle"]):
		game["last_event"] = "%s: the bedroom is too dark" % who
		return

	var symbols = data.get("symbols", [])

	if typeof(symbols) != TYPE_ARRAY:
		game["last_event"] = "%s: invalid symbols" % who
		return

	var result := BedroomRules.try_wheels(game["bedroom"], symbols)

	if result["error"] != "":
		game["last_event"] = "%s: %s" % [who, result["error"]]
	elif result["correct"]:
		game["last_event"] = "%s opened the toy chest!" % who
	else:
		game["penalty_seconds"] += result["penalty_seconds"]
		game["last_event"] = "%s: wrong symbols, -%d s" % [
			who, result["penalty_seconds"]
		]


# Check whether the team can interact with bedroom objects.
static func _can_use_bedroom(game: Dictionary, player: int) -> bool:
	var who := "Player %d" % (player + 1)

	if game.get("location") != "bedroom":
		game["last_event"] = "%s: enter the bedroom first" % who
		return false

	if "bedroom" not in FuseRules.lit_rooms(game["puzzle"]):
		game["last_event"] = "%s: the bedroom is too dark" % who
		return false

	return true


# Take present 3 from the opened chest.
static func _take_bedroom_gift(game: Dictionary, player: int) -> void:
	if not _can_use_bedroom(game, player):
		return

	var who := "Player %d" % (player + 1)
	var result := BedroomRules.take_gift(game["bedroom"])

	if result["ok"]:
		InventoryRules.add(game, "gift_3")
		game["last_event"] = "%s found the third present!" % who
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]


# Take the old photograph from the Advent calendar.
static func _take_bedroom_photo(game: Dictionary, player: int) -> void:
	if not _can_use_bedroom(game, player):
		return

	var who := "Player %d" % (player + 1)
	var result := BedroomRules.take_photo(game["bedroom"])

	if result["ok"]:
		InventoryRules.add(game, "photo_piece_3")  # the photo is torn in three (spec 21)
		game["last_event"] = _photo_piece_message(game, who)
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]


# The key beside the sleeping Jingles (spec 21): into the inventory, then the choice.
static func _take_key(game: Dictionary, player: int) -> void:
	if not _in_attic(game, player):
		return
	var who := "Player %d" % (player + 1)
	var result := AtticRules.take_key(game["attic"])
	if result["ok"]:
		InventoryRules.add(game, "key")
		game["last_event"] = "%s took the key. He didn't wake up... yet." % who
	else:
		game["last_event"] = "%s: %s" % [who, result["error"]]


# A torn piece of the photo (spec 21): only in its room, with the whole team there.
static func _take_piece(game: Dictionary, player: int, data: Dictionary) -> void:
	var who := "Player %d" % (player + 1)
	var room := str(data.get("room", ""))
	if game.get("location") != room:
		game["last_event"] = "%s: go into the %s first" % [who, room]
		return
	var error := PhotoRules.take_piece(game, room)
	if error == "":
		game["last_event"] = _photo_piece_message(game, who)
	else:
		game["last_event"] = "%s: %s" % [who, error]


# The three pieces laid in an order: the right one makes the whole photo (spec 21).
static func _assemble_photo(game: Dictionary, player: int, data: Dictionary) -> void:
	var who := "Player %d" % (player + 1)
	var order = data.get("order", [])
	if typeof(order) != TYPE_ARRAY:
		order = []
	var error := PhotoRules.assemble(game, order)
	if error == "":
		game["last_event"] = "%s put the photo together: Santa and a young, laughing Jingles. Perhaps this memory of happier times could change his mind." % who
	else:
		game["last_event"] = "%s: %s" % [who, error]

static func _photo_piece_message(game: Dictionary, who: String) -> String:
	var all_pieces := true
	for piece in ["photo_piece_1", "photo_piece_2", "photo_piece_3"]:
		if not InventoryRules.has(game, piece):
			all_pieces = false

	if all_pieces:
		return "%s found a torn piece of a photo! You have all three photo pieces. Click the photo slot in your inventory to put them together." % who

	return "%s found a torn piece of a photo!" % who