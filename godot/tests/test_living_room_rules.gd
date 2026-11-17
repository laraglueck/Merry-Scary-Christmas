extends "res://tests/base_test.gd"

const Rules = preload("res://scripts/rules/living_room_rules.gd")


func example_room() -> Dictionary:
	return {
		"hour": 3,
		"minute": 8,
		"digit": 5,
		"solved": false,
		"gift_taken": false,
	}


func test_right_time_solves_clock_without_penalty() -> void:
	var room := example_room()
	var result: Dictionary = Rules.try_clock(room, 3, 8)

	assert_eq(result, {
		"correct": true,
		"penalty_seconds": 0,
		"error": "",
	}, "result")

	var expected := example_room()
	expected["solved"] = true
	assert_eq(room, expected, "only solved changes")


func test_wrong_time_costs_twenty_seconds() -> void:
	var room := example_room()
	var before := room.duplicate(true)

	var result := Rules.try_clock(room, 2, 8)

	assert_eq(result, {
		"correct": false,
		"penalty_seconds": 20,
		"error": "",
	}, "wrong answer")
	assert_eq(room, before, "room unchanged")


func test_invalid_position_is_rejected_without_penalty() -> void:
	var room := example_room()
	var before := room.duplicate(true)

	var result := Rules.try_clock(room, 0, 8)

	assert_true(result["error"] != "", "error explains rejection")
	assert_eq(result["correct"], false, "not accepted")
	assert_eq(result["penalty_seconds"], 0, "no penalty")
	assert_eq(room, before, "room unchanged")


func test_gift_cannot_be_taken_before_solving() -> void:
	var room := example_room()

	var result := Rules.take_gift(room)

	assert_eq(result["taken"], false, "gift refused")
	assert_true(result["error"] != "", "reason given")
	assert_eq(room["gift_taken"], false, "gift remains")


func test_gift_can_only_be_taken_once() -> void:
	var room := example_room()
	Rules.try_clock(room, 3, 8)

	var first := Rules.take_gift(room)
	assert_eq(first["taken"], true, "first pickup succeeds")
	assert_eq(room["gift_taken"], true, "pickup remembered")

	var second := Rules.take_gift(room)
	assert_eq(second["taken"], false, "second pickup refused")
	assert_true(second["error"] != "", "reason given")
	
