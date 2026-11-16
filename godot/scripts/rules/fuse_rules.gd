# Fuse puzzle rules (spec 01).
# Pure functions: no scenes, no network. The game and the server call these.
# Rule: first check, then change. Invalid input changes nothing and
# comes back as an error text (GDScript has no exceptions).
extends RefCounted

const Settings = preload("res://scripts/settings.gd")


static func create_puzzle(rng: RandomNumberGenerator) -> Dictionary:
	# Legend: star, bell, tree, snowflake each get a different wire colour.
	var legend_colours := _shuffled(Settings.WIRE_COLOURS, rng)
	var legend := {}
	for i in Settings.SYMBOLS.size():
		legend[Settings.SYMBOLS[i]] = legend_colours[i]

	# Each fuse gets its own secret wire order.
	var fuses := []
	for fuse in Settings.FUSES:
		fuses.append({
			"colour": fuse["colour"],
			"room": fuse["room"],
			"order": _shuffled(Settings.WIRE_COLOURS, rng),
			"solved": false,
		})
	return {"legend": legend, "fuses": fuses}


static func label_for(puzzle: Dictionary, fuse_index: int) -> Array:
	if not _is_valid_index(fuse_index):
		return []
	var label := []
	for colour in puzzle["fuses"][fuse_index]["order"]:
		label.append(puzzle["legend"].find_key(colour))
	return label


static func label_viewer(fuse_index: int) -> int:
	if not _is_valid_index(fuse_index):
		return -1
	return (fuse_index + 1) % Settings.FUSES.size()


static func try_fuse(puzzle: Dictionary, fuse_index: int, wires: Array) -> Dictionary:
	# 1. Check everything first ...
	var error := _check_attempt(puzzle, fuse_index, wires)
	if error != "":
		return {"correct": false, "penalty_seconds": 0, "error": error}

	# 2. ... then change.
	var fuse: Dictionary = puzzle["fuses"][fuse_index]
	if wires == fuse["order"]:
		fuse["solved"] = true
		return {"correct": true, "penalty_seconds": 0, "error": ""}
	return {"correct": false, "penalty_seconds": Settings.FUSE_PENALTY_SECONDS, "error": ""}


# Derived, not stored: always computed fresh from the fuses.
static func lit_rooms(puzzle: Dictionary) -> Array:
	var rooms := []
	for fuse in puzzle["fuses"]:
		if fuse["solved"]:
			rooms.append(fuse["room"])
	return rooms


# Returns "" if the attempt is valid, otherwise the reason.
static func _check_attempt(puzzle: Dictionary, fuse_index: int, wires: Array) -> String:
	if not _is_valid_index(fuse_index):
		return "Invalid fuse index: %d" % fuse_index
	if puzzle["fuses"][fuse_index]["solved"]:
		return "Fuse %d is already solved" % fuse_index
	var wire_count := Settings.WIRE_COLOURS.size()
	if wires.size() != wire_count:
		return "Expected %d wires, got %d" % [wire_count, wires.size()]
	for colour in wires:
		if colour not in Settings.WIRE_COLOURS:
			return "Unknown wire colour: %s" % colour
	for colour in wires:
		if wires.count(colour) > 1:
			return "Wire colour used twice: %s" % colour
	return ""


static func _is_valid_index(fuse_index: int) -> bool:
	return fuse_index >= 0 and fuse_index < Settings.FUSES.size()


# Returns a shuffled copy (Fisher-Yates). The settings list itself stays as it is.
static func _shuffled(items: Array, rng: RandomNumberGenerator) -> Array:
	var copy := items.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = copy[i]
		copy[i] = copy[j]
		copy[j] = temp
	return copy
