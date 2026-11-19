# Tests for spec 21: the photo torn in three pieces and putting it together.
extends "res://tests/base_test.gd"

const PhotoRules = preload("res://scripts/rules/photo_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")

const RIGHT := ["photo_piece_1", "photo_piece_2", "photo_piece_3"]


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func game_with_all_pieces() -> Dictionary:
	var game := new_game()
	for piece in RIGHT:
		InventoryRules.add(game, piece)
	return game


# ---------- finding the pieces ----------

func test_each_room_holds_one_piece() -> void:
	assert_eq(PhotoRules.PIECE_IN_ROOM, {"living_room": "photo_piece_1", "bathroom": "photo_piece_2",
			"bedroom": "photo_piece_3"}, "one piece per room")


func test_a_piece_is_found_only_after_the_rooms_lock() -> void:
	var game := new_game()
	assert_contains(PhotoRules.take_piece(game, "bathroom"), "not", "refused before the taps")
	assert_true(not InventoryRules.has(game, "photo_piece_2"), "nothing taken")
	game["bathroom"]["solved"] = true
	assert_eq(PhotoRules.take_piece(game, "bathroom"), "", "taken after solving")
	assert_true(InventoryRules.has(game, "photo_piece_2"), "in the inventory")
	assert_contains(PhotoRules.take_piece(game, "bathroom"), "already", "only once")


func test_a_piece_from_a_room_without_one_is_refused() -> void:
	assert_contains(PhotoRules.take_piece(new_game(), "attic"), "no piece", "the attic has none")


# ---------- putting it together ----------

func test_all_found() -> void:
	var game := new_game()
	assert_eq(PhotoRules.all_found(game), false, "none yet")
	assert_eq(PhotoRules.all_found(game_with_all_pieces()), true, "all three")


func test_the_right_order_makes_the_whole_photo() -> void:
	var game := game_with_all_pieces()
	assert_eq(PhotoRules.assemble(game, RIGHT), "", "fits")
	assert_true(InventoryRules.has(game, "photo"), "the whole photo")
	for piece in RIGHT:
		assert_true(not InventoryRules.has(game, piece), "%s is gone" % piece)


func test_a_wrong_order_does_not_fit_and_changes_nothing() -> void:
	var game := game_with_all_pieces()
	var before := game.duplicate(true)
	assert_contains(PhotoRules.assemble(game, ["photo_piece_2", "photo_piece_1", "photo_piece_3"]), "don't fit", "wrong")
	assert_eq(game, before, "nothing changed")


func test_putting_together_needs_all_three() -> void:
	var game := new_game()
	InventoryRules.add(game, "photo_piece_1")
	assert_contains(PhotoRules.assemble(game, RIGHT), "all three", "refused")
	assert_true(not InventoryRules.has(game, "photo"), "no photo")


# ---------- in the shared game ----------

func test_take_piece_and_assemble_through_the_game() -> void:
	var game := new_game()
	game["bathroom"]["solved"] = true
	game["location"] = "bathroom"
	GameRules.apply(game, 1, "take_piece", {"room": "bathroom"})
	assert_true(InventoryRules.has(game, "photo_piece_2"), "piece taken")
	assert_contains(game["last_event"], "Player 2 found a torn piece of a photo", "event")
	InventoryRules.add(game, "photo_piece_1")
	InventoryRules.add(game, "photo_piece_3")
	GameRules.apply(game, 0, "assemble_photo", {"order": RIGHT})
	assert_true(InventoryRules.has(game, "photo"), "whole photo")
	assert_contains(game["last_event"], "young, laughing Jingles", "event")


func test_a_piece_needs_the_team_in_that_room() -> void:
	var game := new_game()
	game["bathroom"]["solved"] = true  # the team stands in the hall
	GameRules.apply(game, 0, "take_piece", {"room": "bathroom"})
	assert_true(not InventoryRules.has(game, "photo_piece_2"), "not from the hall")
