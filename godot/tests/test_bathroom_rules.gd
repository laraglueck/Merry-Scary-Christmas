# Tests for spec 10: bathroom rules (the tap lock, the present, the mirror).
extends "res://tests/base_test.gd"

const Rules = preload("res://scripts/rules/bathroom_rules.gd")
const Settings = preload("res://scripts/settings.gd")

const RIGHT_TAPS := ["hot", "cold", "cold", "hot"]


# A hand-made bathroom with fixed values, so we know every answer.
func example_room() -> Dictionary:
	return {"tap_order": RIGHT_TAPS.duplicate(), "turns": [], "digit": 7, "solved": false, "gift_taken": false}


func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# Invalid input: error text contains the reason, no penalty, room unchanged.
func assert_rejected(room: Dictionary, taps: Array, reason: String) -> void:
	var before := room.duplicate(true)
	var result := Rules.try_taps(room, taps)
	assert_contains(result.get("error", ""), reason, "error text")
	assert_eq(result.get("correct"), false, "correct")
	assert_eq(result.get("penalty_seconds"), 0, "no penalty for invalid input")
	assert_eq(room, before, "room unchanged")


# ---------- create ----------

func test_new_bathroom_has_four_turns_a_digit_and_is_unsolved() -> void:
	var room := Rules.create(make_rng(1))
	assert_eq(room.get("tap_order", []).size(), 4, "four turns")
	for tap in room.get("tap_order", []):
		assert_true(tap in Settings.TAPS, "turn %s is hot or cold" % tap)
	var digit: int = room.get("digit", 0)
	assert_true(digit >= 1 and digit <= 9, "digit %d is 1 to 9" % digit)
	assert_eq(room.get("solved"), false, "not solved")
	assert_eq(room.get("gift_taken"), false, "present not taken")
	assert_eq(room.get("turns"), [], "no turns yet")


func test_bathroom_has_only_the_agreed_keys() -> void:
	var keys := Rules.create(make_rng(1)).keys()
	keys.sort()
	assert_eq(keys, ["digit", "gift_taken", "solved", "tap_order", "turns"], "keys")


func test_same_seed_gives_same_bathroom() -> void:
	var first := Rules.create(make_rng(42))
	assert_true(not first.is_empty(), "bathroom not empty")
	assert_eq(first, Rules.create(make_rng(42)), "seed 42 twice")


func test_different_seeds_give_different_bathrooms() -> void:
	var seen := {}
	for seed_value in [1, 2, 3, 4, 5, 6, 7, 8]:
		seen[str(Rules.create(make_rng(seed_value)))] = true
	assert_true(seen.size() > 1, "8 seeds give more than one bathroom")


# ---------- try_taps ----------

func test_right_order_solves_the_taps_without_penalty() -> void:
	var room := example_room()
	var result := Rules.try_taps(room, RIGHT_TAPS)
	assert_eq(result, {"correct": true, "penalty_seconds": 0, "error": ""}, "result")
	assert_eq(room["solved"], true, "solved")


func test_wrong_order_costs_twenty_seconds_and_changes_nothing() -> void:
	var room := example_room()
	var before := room.duplicate(true)
	var result := Rules.try_taps(room, ["cold", "cold", "cold", "hot"])
	assert_eq(result, {"correct": false, "penalty_seconds": 20, "error": ""}, "result")
	assert_eq(Settings.TAP_PENALTY_SECONDS, 20, "penalty comes from settings")
	assert_eq(room, before, "room unchanged")


# ---------- rejections: error text, nothing changes ----------

func test_rejects_three_turns() -> void:
	assert_rejected(example_room(), ["hot", "cold", "cold"], "expected 4 turns")


func test_rejects_five_turns() -> void:
	assert_rejected(example_room(), ["hot", "cold", "cold", "hot", "hot"], "expected 4 turns")


func test_rejects_unknown_turn() -> void:
	assert_rejected(example_room(), ["hot", "warm", "cold", "hot"], "unknown turn")


func test_rejects_taps_when_already_solved() -> void:
	var room := example_room()
	room["solved"] = true
	assert_rejected(room, RIGHT_TAPS, "already solved")


# ---------- add_turn: one turn at a time, shared by the whole team ----------

func add_turns(room: Dictionary, taps: Array) -> Dictionary:
	var result := {}
	for tap in taps:
		result = Rules.add_turn(room, tap)
	return result


func test_a_turn_is_added_and_nothing_is_tried_yet() -> void:
	var room := example_room()
	var result := Rules.add_turn(room, "hot")
	assert_eq(result, {"tried": false, "correct": false, "penalty_seconds": 0, "error": ""}, "result")
	assert_eq(room["turns"], ["hot"], "turns")


func test_four_right_turns_solve_the_taps_and_clear_the_turns() -> void:
	var room := example_room()
	var result := add_turns(room, RIGHT_TAPS)
	assert_eq(result, {"tried": true, "correct": true, "penalty_seconds": 0, "error": ""}, "result")
	assert_eq(room["solved"], true, "solved")
	assert_eq(room["turns"], [], "turns cleared")


func test_four_wrong_turns_cost_20_seconds_and_start_over() -> void:
	var room := example_room()
	var result := add_turns(room, ["cold", "cold", "cold", "hot"])
	assert_eq(result, {"tried": true, "correct": false, "penalty_seconds": 20, "error": ""}, "result")
	assert_eq(room["solved"], false, "not solved")
	assert_eq(room["turns"], [], "turns cleared, start over")


func test_an_unknown_turn_is_refused_and_changes_nothing() -> void:
	var room := example_room()
	Rules.add_turn(room, "hot")
	var before := room.duplicate(true)
	var result := Rules.add_turn(room, "warm")
	assert_contains(result.get("error", ""), "unknown turn", "error text")
	assert_eq(room, before, "room unchanged")


func test_a_turn_after_solving_is_refused() -> void:
	var room := example_room()
	add_turns(room, RIGHT_TAPS)
	var before := room.duplicate(true)
	var result := Rules.add_turn(room, "hot")
	assert_contains(result.get("error", ""), "already solved", "error text")
	assert_eq(room, before, "room unchanged")


# ---------- take_gift ----------

func test_present_is_refused_before_solving() -> void:
	var room := example_room()
	var result := Rules.take_gift(room)
	assert_eq(result.get("ok"), false, "refused")
	assert_contains(result.get("error", ""), "not solved", "error text")
	assert_eq(room["gift_taken"], false, "present still there")


func test_present_can_be_taken_after_solving() -> void:
	var room := example_room()
	Rules.try_taps(room, RIGHT_TAPS)
	assert_eq(Rules.take_gift(room), {"ok": true, "error": ""}, "result")
	assert_eq(room["gift_taken"], true, "present taken")


func test_present_cannot_be_taken_twice() -> void:
	var room := example_room()
	Rules.try_taps(room, RIGHT_TAPS)
	Rules.take_gift(room)
	var result := Rules.take_gift(room)
	assert_eq(result.get("ok"), false, "second time refused")
	assert_contains(result.get("error", ""), "already taken", "error text")


# ---------- mirror_symbols ----------

func test_mirror_shows_the_chest_symbols_in_reverse_order() -> void:
	assert_eq(Rules.mirror_symbols(["bell", "star", "tree"]), ["tree", "star", "bell"], "mirrored")


func test_mirror_does_not_change_the_bedroom_wheels() -> void:
	var wheels := ["bell", "star", "tree"]
	Rules.mirror_symbols(wheels)
	assert_eq(wheels, ["bell", "star", "tree"], "wheels unchanged")
