# Tests for spec 10: the bathroom inside the shared game (GameRules.apply).
extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")

const GREEN_FUSE := 1  # the green fuse lights the bathroom


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


# A game where the green fuse is already on, so the bathroom is lit.
func game_with_bathroom_lit() -> Dictionary:
	var game := new_game()
	var order: Array = game["puzzle"]["fuses"][GREEN_FUSE]["order"].duplicate()
	FuseRules.try_fuse(game["puzzle"], GREEN_FUSE, order)
	return game


func right_taps(game: Dictionary) -> Array:
	return game["bathroom"]["tap_order"].duplicate()


func wrong_taps(game: Dictionary) -> Array:
	var taps := right_taps(game)
	taps[0] = "cold" if taps[0] == "hot" else "hot"  # one turn different
	return taps


func test_new_game_has_an_unsolved_bathroom() -> void:
	var bathroom: Dictionary = new_game().get("bathroom", {})
	assert_eq(bathroom.get("tap_order", []).size(), 4, "four turns")
	assert_eq(bathroom.get("solved"), false, "not solved")
	assert_eq(bathroom.get("gift_taken"), false, "present not taken")


func test_right_taps_solve_the_bathroom() -> void:
	var game := game_with_bathroom_lit()
	GameRules.apply(game, 0, "turn_taps", {"taps": right_taps(game)})
	assert_eq(game["bathroom"]["solved"], true, "solved")
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_eq(game["last_event"], "Player 1: the pipes rattle and the water drains away.", "event")


func test_wrong_taps_cost_20_seconds() -> void:
	var game := game_with_bathroom_lit()
	GameRules.apply(game, 2, "turn_taps", {"taps": wrong_taps(game)})
	assert_eq(game["bathroom"]["solved"], false, "not solved")
	assert_eq(game["penalty_seconds"], 20, "penalty")
	assert_eq(game["last_event"], "Player 3: the pipes rattle angrily, -20 s", "event")


func test_invalid_taps_give_the_reason_without_penalty() -> void:
	var game := game_with_bathroom_lit()
	var before: Dictionary = game["bathroom"].duplicate(true)
	GameRules.apply(game, 1, "turn_taps", {"taps": ["hot", "warm"]})
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "Player 2", "who")
	assert_contains(game["last_event"], "expected 4 turns", "reason")
	assert_eq(game["bathroom"], before, "bathroom unchanged")


func test_missing_taps_are_invalid_not_a_crash() -> void:
	var game := game_with_bathroom_lit()
	GameRules.apply(game, 0, "turn_taps", {})
	assert_contains(game.get("last_event", ""), "expected 4 turns", "reason")


func test_taps_are_refused_while_the_bathroom_is_dark() -> void:
	var game := new_game()  # green fuse still off
	var before: Dictionary = game["bathroom"].duplicate(true)
	GameRules.apply(game, 0, "turn_taps", {"taps": right_taps(game)})
	assert_eq(game["bathroom"], before, "bathroom unchanged")
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "too dark", "reason")


func test_present_can_be_taken_once_after_solving() -> void:
	var game := game_with_bathroom_lit()
	GameRules.apply(game, 0, "turn_taps", {"taps": right_taps(game)})
	GameRules.apply(game, 1, "take_gift", {"room": "bathroom"})
	assert_eq(game["bathroom"]["gift_taken"], true, "taken")
	assert_eq(game["last_event"], "Player 2 found the second present!", "event")
	GameRules.apply(game, 2, "take_gift", {"room": "bathroom"})
	assert_contains(game["last_event"], "already taken", "second time refused")


func test_present_is_refused_before_solving() -> void:
	var game := game_with_bathroom_lit()
	GameRules.apply(game, 0, "take_gift", {"room": "bathroom"})
	assert_eq(game["bathroom"]["gift_taken"], false, "still there")
	assert_contains(game["last_event"], "not solved", "reason")


func test_present_from_an_unknown_room_changes_nothing() -> void:
	var game := game_with_bathroom_lit()
	var before := game.duplicate(true)
	GameRules.apply(game, 0, "take_gift", {"room": "kitchen"})
	assert_eq(game, before, "unchanged")
