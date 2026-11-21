# Bedroom puzzle rules.
# This file contains game logic, not visual elements.
extends RefCounted
const SYMBOLS = ["star", "bell", "tree", "snowflake"]


static func create_room(rng: RandomNumberGenerator) -> Dictionary:
	var solution: Array[String] = []

	for i in range(3):
		var symbol = SYMBOLS[rng.randi_range(0, SYMBOLS.size() - 1)]
		solution.append(symbol)

	return {
		"wheels": solution,
		"selected_wheels": ["star", "star", "star"],
		"digit": rng.randi_range(1, 9),
		"solved": false,
		"gift_taken": false,
		"photo_taken": false
			}

# Check the three symbols entered by the players.
static func try_wheels(room: Dictionary, symbols: Array) -> Dictionary:
	if symbols.size() != 3:
		return {"error": "Choose exactly three symbols.", "correct": false, "penalty_seconds": 0}

	for symbol in symbols:
		if typeof(symbol) != TYPE_STRING or symbol not in SYMBOLS:
			return {"error": "Invalid symbol.", "correct": false, "penalty_seconds": 0}

	if room["solved"]:
		return {"error": "The chest is already open.", "correct": false, "penalty_seconds": 0}

	room["selected_wheels"] = symbols.duplicate()

	if symbols == room["wheels"]:
		room["solved"] = true
		return {"error": "", "correct": true, "penalty_seconds": 0}

	return {"error": "", "correct": false, "penalty_seconds": 20}


# Take present 3 from the chest after solving the puzzle.
static func take_gift(room: Dictionary) -> Dictionary:
	if not room["solved"]:
		return {"ok": false, "error": "Open the chest first."}

	if room["gift_taken"]:
		return {"ok": false, "error": "The present was already taken."}

	room["gift_taken"] = true
	return {"ok": true, "error": ""}


# Take the old photograph from the Advent calendar.
static func take_photo(room: Dictionary) -> Dictionary:
	if room["photo_taken"]:
		return {"ok": false, "error": "The photo was already taken."}

	if not room.get("solved", false):
		return {"ok": false, "error": "Open the chest first."}
	room["photo_taken"] = true
	return {"ok": true, "error": ""}


# Derive a stable door from existing saved state, excluding both clock clues.
static func photo_door(room: Dictionary, clue: Dictionary) -> int:
	var candidates: Array[int] = []
	for door in range(1, 13):
		if door != int(clue.get("hour", 0)) and door != int(clue.get("minute", 0)):
			candidates.append(door)
	return candidates[posmod(int(room.get("digit", 0)), candidates.size())]


# Spec 28: the five doors with an Easter-egg picture (index i = egg i + 1). Like photo_door,
# derived from the saved state (wheels and digit), so it is random per game but stays the same
# after save/resume. Never a clock-hand door, never the photo door.
static func egg_doors(room: Dictionary, clue: Dictionary) -> Array[int]:
	var taken := [int(clue.get("hour", 0)), int(clue.get("minute", 0)), photo_door(room, clue)]
	var candidates: Array[int] = []
	for door in range(1, 13):
		if door not in taken:
			candidates.append(door)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(room.get("wheels", [])) + str(room.get("digit", 0)))
	for i in range(candidates.size() - 1, 0, -1):  # shuffle with our own seed, not the global one
		var j := rng.randi_range(0, i)
		var swap := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	return candidates.slice(0, 5)


# Older saves could contain zero, which would otherwise skip the attic's gold dial.
static func gold_digit(room: Dictionary) -> int:
	return maxi(1, int(room["digit"]))
