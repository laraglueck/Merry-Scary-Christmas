# Tests for spec 21: the puzzle window where the three torn pieces are put together.
extends "res://tests/base_test.gd"

const PuzzleScene = preload("res://scenes/photo_puzzle.tscn")
const RIGHT := ["photo_piece_1", "photo_piece_2", "photo_piece_3"]


# Stands in for network.gd: records what the window sends.
class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {"inventory": ["photo_piece_2", "photo_piece_3", "photo_piece_1"]}
	var sent: Array = []

	func send_action(action: String, data: Dictionary) -> void:
		sent.append([action, data])


func open_puzzle() -> Array:
	var net := FakeNet.new()
	tree.root.add_child(net)
	var puzzle = PuzzleScene.instantiate()
	puzzle.net = net
	tree.root.add_child(puzzle)
	return [puzzle, net]


func test_the_pieces_start_jumbled() -> void:
	var puzzle = open_puzzle()[0]
	assert_eq(puzzle.order().size(), 3, "three pieces")
	assert_true(puzzle.order() != RIGHT, "not already in order")


func test_clicking_two_pieces_swaps_them() -> void:
	var puzzle = open_puzzle()[0]
	var before: Array = puzzle.order()
	press(puzzle, "PuzzlePiece0")
	press(puzzle, "PuzzlePiece2")
	assert_eq(puzzle.order(), [before[2], before[1], before[0]], "first and last swapped")


func test_the_right_order_puts_the_photo_together() -> void:
	var parts := open_puzzle()
	var puzzle = parts[0]
	var net = parts[1]
	# Swap pieces until they are in the right order, like a player would.
	for slot in 3:
		var at: int = puzzle.order().find(RIGHT[slot])
		if at != slot:
			press(puzzle, "PuzzlePiece%d" % slot)
			press(puzzle, "PuzzlePiece%d" % at)
	assert_eq(puzzle.order(), RIGHT, "in order")
	assert_eq(net.sent, [["assemble_photo", {"order": RIGHT}]], "sent to the host once")
	assert_true(find(puzzle, "WholePhoto").visible, "the whole photo shows")
