# Photo rules (spec 21): the photo of Santa and young Jingles is torn in three pieces,
# one in each room. With all three the team puts it together, and the whole photo
# opens the Merry Christmas ending in the attic.
# Pure functions: no scenes, no network. First check, then change; a refused action
# changes nothing and comes back as an error text.
extends RefCounted

const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")

const PIECES := ["photo_piece_1", "photo_piece_2", "photo_piece_3"]  # left to right
const PIECE_IN_ROOM := {"living_room": "photo_piece_1", "bathroom": "photo_piece_2",
		"bedroom": "photo_piece_3"}
const WHOLE := "photo"


# A room's piece, once that room's lock is solved.
static func take_piece(game: Dictionary, room: String) -> String:
	# 1. Check ...
	if not PIECE_IN_ROOM.has(room):
		return "There is no piece of the photo in the %s." % room
	var piece: String = PIECE_IN_ROOM[room]
	if InventoryRules.has(game, piece) or InventoryRules.has(game, WHOLE):
		return "The team already has this piece."
	if not game.get(room, {}).get("solved", false):
		return "The piece is not there yet."
	# 2. ... then change.
	return InventoryRules.add(game, piece)


static func all_found(game: Dictionary) -> bool:
	for piece in PIECES:
		if not InventoryRules.has(game, piece):
			return false
	return true


# The pieces laid side by side in this order (left to right). Only the right order fits;
# then the three pieces become the whole photo.
static func assemble(game: Dictionary, order: Array) -> String:
	# 1. Check ...
	if InventoryRules.has(game, WHOLE):
		return "The photo is already whole."
	if not all_found(game):
		return "Find all three pieces first."
	if order != PIECES:
		return "The torn edges don't fit like this."
	# 2. ... then change.
	for piece in PIECES:
		game["inventory"].erase(piece)
	return InventoryRules.add(game, WHOLE)
