# Tests for spec 01: fuse puzzle rules.
extends "res://tests/base_test.gd"

const Rules = preload("res://scripts/rules/fuse_rules.gd")
const Settings = preload("res://scripts/settings.gd")

const RIGHT_ORDER_FUSE_0 := ["white", "blue", "black", "yellow"]


# A hand-made puzzle with fixed values, so we know every answer.
func example_puzzle() -> Dictionary:
	return {
		"legend": {"star": "blue", "bell": "yellow", "tree": "white", "snowflake": "black"},
		"fuses": [
			{"colour": "red", "room": "living/dining room", "order": ["white", "blue", "black", "yellow"], "solved": false},
			{"colour": "green", "room": "bathroom", "order": ["black", "yellow", "blue", "white"], "solved": false},
			{"colour": "gold", "room": "bedroom", "order": ["yellow", "white", "black", "blue"], "solved": false},
		],
	}


func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func sorted(items: Array) -> Array:
	var copy := items.duplicate()
	copy.sort()
	return copy


# Invalid input: error text contains the reason, no penalty, puzzle unchanged.
func assert_rejected(puzzle: Dictionary, fuse_index: int, wires: Array, reason: String) -> void:
	var before := puzzle.duplicate(true)
	var result := Rules.try_fuse(puzzle, fuse_index, wires)
	assert_contains(result.get("error", ""), reason, "error text")
	assert_eq(result.get("correct"), false, "correct")
	assert_eq(result.get("penalty_seconds"), 0, "no penalty for invalid input")
	assert_eq(puzzle, before, "puzzle unchanged")


# ---------- create_puzzle ----------

func test_new_puzzle_has_three_unsolved_fuses_with_colour_and_room() -> void:
	var puzzle := Rules.create_puzzle(make_rng(1))
	var summary := []
	for fuse in puzzle.get("fuses", []):
		summary.append([fuse["colour"], fuse["room"], fuse["solved"]])
	assert_eq(summary, [
		["red", "living/dining room", false],
		["green", "bathroom", false],
		["gold", "bedroom", false],
	], "fuses")


func test_each_fuse_order_uses_all_four_colours_once() -> void:
	var puzzle := Rules.create_puzzle(make_rng(1))
	assert_eq(puzzle.get("fuses", []).size(), 3, "number of fuses")
	for fuse in puzzle.get("fuses", []):
		assert_eq(sorted(fuse["order"]), sorted(Settings.WIRE_COLOURS), "wire order")


func test_legend_gives_each_symbol_a_different_colour() -> void:
	var legend: Dictionary = Rules.create_puzzle(make_rng(1)).get("legend", {})
	assert_eq(sorted(legend.keys()), sorted(Settings.SYMBOLS), "legend symbols")
	assert_eq(sorted(legend.values()), sorted(Settings.WIRE_COLOURS), "legend colours")


func test_same_seed_gives_same_puzzle() -> void:
	var first := Rules.create_puzzle(make_rng(42))
	assert_true(not first.is_empty(), "puzzle not empty")
	assert_eq(first, Rules.create_puzzle(make_rng(42)), "seed 42 twice")


func test_different_seeds_give_different_puzzles() -> void:
	var seen := {}
	for seed_value in [1, 2, 3, 4, 5]:
		seen[str(Rules.create_puzzle(make_rng(seed_value)))] = true
	assert_true(seen.size() > 1, "5 seeds give more than one puzzle")


# ---------- label_for ----------

func test_label_shows_order_as_symbols() -> void:
	# order white, blue, black, yellow -> tree, star, snowflake, bell
	assert_eq(Rules.label_for(example_puzzle(), 0), ["tree", "star", "snowflake", "bell"], "label fuse 0")


func test_plausibility_label_back_through_legend_equals_order() -> void:
	var puzzle := Rules.create_puzzle(make_rng(7))
	for i in 3:
		var back_to_colours := []
		for symbol in Rules.label_for(puzzle, i):
			back_to_colours.append(puzzle["legend"][symbol])
		assert_eq(back_to_colours, puzzle["fuses"][i]["order"], "fuse %d" % i)


func test_invalid_index_gives_empty_label_and_no_viewer() -> void:
	assert_eq(Rules.label_for(example_puzzle(), 3), [], "label_for index 3")
	assert_eq(Rules.label_viewer(-1), -1, "label_viewer index -1")


# ---------- label_viewer ----------

func test_label_goes_to_next_player_never_owner() -> void:
	assert_eq([Rules.label_viewer(0), Rules.label_viewer(1), Rules.label_viewer(2)], [1, 2, 0], "viewers")


# ---------- try_fuse ----------

func test_right_order_solves_fuse_without_penalty() -> void:
	var puzzle := example_puzzle()
	var result := Rules.try_fuse(puzzle, 0, RIGHT_ORDER_FUSE_0)
	assert_eq(result, {"correct": true, "penalty_seconds": 0, "error": ""}, "result")
	assert_eq(puzzle["fuses"][0]["solved"], true, "fuse 0 solved")
	assert_eq(puzzle["fuses"][1]["solved"], false, "fuse 1 untouched")
	assert_eq(puzzle["fuses"][2]["solved"], false, "fuse 2 untouched")


func test_wrong_order_costs_ten_seconds_and_changes_nothing() -> void:
	var puzzle := example_puzzle()
	var before := puzzle.duplicate(true)
	var result := Rules.try_fuse(puzzle, 0, ["blue", "white", "black", "yellow"])
	assert_eq(result, {"correct": false, "penalty_seconds": 10, "error": ""}, "result")
	assert_eq(Settings.FUSE_PENALTY_SECONDS, 10, "penalty comes from settings")
	assert_eq(puzzle, before, "puzzle unchanged")


# ---------- rejections: error text, nothing changes ----------

func test_rejects_fuse_index_minus_one() -> void:
	assert_rejected(example_puzzle(), -1, RIGHT_ORDER_FUSE_0, "invalid fuse index")


func test_rejects_fuse_index_three() -> void:
	assert_rejected(example_puzzle(), 3, RIGHT_ORDER_FUSE_0, "invalid fuse index")


func test_rejects_three_wires() -> void:
	assert_rejected(example_puzzle(), 0, ["white", "blue", "black"], "expected 4 wires")


func test_rejects_five_wires() -> void:
	assert_rejected(example_puzzle(), 0, ["white", "blue", "black", "yellow", "blue"], "expected 4 wires")


func test_rejects_unknown_colour() -> void:
	assert_rejected(example_puzzle(), 0, ["white", "blue", "black", "red"], "unknown wire colour")


func test_rejects_colour_twice() -> void:
	assert_rejected(example_puzzle(), 0, ["white", "blue", "blue", "yellow"], "used twice")


func test_rejects_already_solved_fuse() -> void:
	var puzzle := example_puzzle()
	puzzle["fuses"][0]["solved"] = true
	assert_rejected(puzzle, 0, RIGHT_ORDER_FUSE_0, "already solved")


# ---------- lit_rooms ----------

func test_no_rooms_lit_at_start() -> void:
	assert_eq(Rules.lit_rooms(example_puzzle()), [], "lit rooms")


func test_solving_green_fuse_lights_bathroom() -> void:
	var puzzle := example_puzzle()
	Rules.try_fuse(puzzle, 1, ["black", "yellow", "blue", "white"])
	assert_eq(Rules.lit_rooms(puzzle), ["bathroom"], "lit rooms")


func test_lit_rooms_are_derived_not_stored() -> void:
	var puzzle := Rules.create_puzzle(make_rng(1))
	assert_eq(sorted(puzzle.keys()), ["fuses", "legend"], "puzzle keys")
	for fuse in puzzle.get("fuses", []):
		assert_eq(sorted(fuse.keys()), ["colour", "order", "room", "solved"], "fuse keys")
