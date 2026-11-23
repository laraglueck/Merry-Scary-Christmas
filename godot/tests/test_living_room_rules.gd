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
	
func test_rhyme_matches_tap_order() -> void:
	var taps := ["hot", "cold", "cold", "hot"]
	var before := taps.duplicate()

	var lines: Array[String] = Rules.rhyme_for(taps)

	assert_eq(lines, [
		"First, warm as fire burning bright,",
		"Then, cold as snow on Christmas night.",
		"Again, cold as the winds that blow,",
		"Last, warm as embers burning low.",
	], "rhyme follows the bathroom answer")

	assert_eq(taps, before, "tap order unchanged")
	
func test_rhyme_matches_all_sixteen_orders() -> void:
	for combination in range(16):
		var taps: Array = []

		for i in range(4):
			taps.append(
				"hot" if (combination & (1 << i)) != 0 else "cold"
			)

		var before := taps.duplicate()
		var lines := Rules.rhyme_for(taps)

		assert_eq(lines.size(), 4, "four lines")
		if lines.size() != 4:
			continue

		for i in range(4):
			var expected_word := "warm" if taps[i] == "hot" else "cold"
			assert_contains(lines[i], expected_word, "line matches tap")

		assert_eq(taps, before, "tap order unchanged")


func test_rhyme_rejects_invalid_orders() -> void:
	for taps in [
		[],
		["hot", "cold", "hot"],
		["hot", "cold", "hot", "cold", "hot"],
		["hot", "cold", "unknown", "hot"],
		["hot", "cold", 1, "hot"],
	]:
		assert_eq(Rules.rhyme_for(taps), [], "invalid order refused")
		
func test_created_room_has_valid_values() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in range(100):
		var room := Rules.create_room(rng)

		assert_true(
			room["hour"] >= 1 and room["hour"] <= 12,
			"hour between 1 and 12"
		)
		assert_true(
			room["minute"] >= 1 and room["minute"] <= 12,
			"minute between 1 and 12"
		)
		assert_true(
			room["hour"] != room["minute"],
			"hands have different positions"
		)
		assert_true(
			room["digit"] >= 1 and room["digit"] <= 9,
			"digit between 1 and 9"
		)
		assert_eq(room["solved"], false, "starts unsolved")
		assert_eq(room["gift_taken"], false, "gift not taken")


func test_same_seed_creates_same_room() -> void:
	var first_rng := RandomNumberGenerator.new()
	first_rng.seed = 42

	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 42

	assert_eq(
		Rules.create_room(first_rng),
		Rules.create_room(second_rng),
		"same seed gives same room"
	)


func test_all_out_of_range_positions_are_rejected() -> void:
	for positions in [
		[0, 8],
		[13, 8],
		[3, 0],
		[3, 13],
	]:
		var room := example_room()
		var before := room.duplicate(true)
		var result := Rules.try_clock(
			room, positions[0], positions[1]
		)

		assert_eq(result["correct"], false, "not accepted")
		assert_eq(result["penalty_seconds"], 0, "no penalty")
		assert_true(result["error"] != "", "reason given")
		assert_eq(room, before, "room unchanged")


func test_solved_clock_cannot_be_tried_again() -> void:
	var room := example_room()
	Rules.try_clock(room, 3, 8)
	var before := room.duplicate(true)

	for positions in [[3, 8], [2, 8]]:
		var result := Rules.try_clock(
			room, positions[0], positions[1]
		)

		assert_eq(result["correct"], false, "retry refused")
		assert_eq(result["penalty_seconds"], 0, "no extra penalty")
		assert_true(result["error"] != "", "reason given")
		assert_eq(room, before, "solved room unchanged")
		
func test_equal_clock_positions_are_rejected_without_penalty() -> void:
	var room := example_room()
	var before := room.duplicate(true)

	var result := Rules.try_clock(room, 3, 3)

	assert_eq(result["correct"], false, "not accepted")
	assert_eq(result["penalty_seconds"], 0, "no penalty")
	assert_true(result["error"] != "", "reason given")
	assert_eq(room, before, "room unchanged")
	
