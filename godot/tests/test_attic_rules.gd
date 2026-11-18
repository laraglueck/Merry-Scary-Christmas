# Tests for spec 16: attic rules (the code lock and the final choice).
extends "res://tests/base_test.gd"

const Rules = preload("res://scripts/rules/attic_rules.gd")

const CODE := [3, 7, 5]  # red, green, gold


func closed_attic() -> Dictionary:
	return Rules.create()


func open_attic() -> Dictionary:
	var attic := Rules.create()
	attic["unlocked"] = true
	return attic


# A refused code: error text contains the reason, no penalty, attic unchanged.
func assert_code_rejected(attic: Dictionary, dials: Array, reason: String) -> void:
	var before := attic.duplicate(true)
	var result := Rules.try_code(attic, dials, CODE)
	assert_contains(result.get("error", ""), reason, "error text")
	assert_eq(result.get("correct"), false, "correct")
	assert_eq(result.get("penalty_seconds"), 0, "no penalty for invalid input")
	assert_eq(attic, before, "attic unchanged")


# A refused choice: error text contains the reason, no ending, attic unchanged.
func assert_choice_rejected(attic: Dictionary, choice: String, has_photo: bool, reason: String) -> void:
	var before := attic.duplicate(true)
	var result := Rules.choose(attic, choice, has_photo)
	assert_contains(result.get("error", ""), reason, "error text")
	assert_eq(result.get("ending"), "", "no ending")
	assert_eq(attic, before, "attic unchanged")


# ---------- create and code ----------

func test_new_attic_is_locked_and_nothing_is_chosen() -> void:
	assert_eq(Rules.create(), {"unlocked": false, "choice": ""}, "new attic")


func test_code_is_the_three_room_digits() -> void:
	var game := {"living_room": {"digit": 3}, "bathroom": {"digit": 7}, "bedroom": {"digit": 5}}
	assert_eq(Rules.code(game), [3, 7, 5], "red, green, gold")


func test_without_a_bedroom_the_gold_digit_is_not_checked_yet() -> void:
	var game := {"living_room": {"digit": 3}, "bathroom": {"digit": 7}}
	assert_eq(Rules.code(game), [3, 7, 0], "gold is 0 until the bedroom exists")
	for gold in [1, 9]:
		var attic := closed_attic()
		var result := Rules.try_code(attic, [3, 7, gold], Rules.code(game))
		assert_eq(result["correct"], true, "any gold digit %d counts" % gold)


# ---------- the code lock ----------

func test_right_code_opens_the_lock() -> void:
	var attic := closed_attic()
	var result := Rules.try_code(attic, [3, 7, 5], CODE)
	assert_eq(result, {"correct": true, "penalty_seconds": 0, "error": ""}, "result")
	assert_eq(attic["unlocked"], true, "unlocked")


func test_wrong_code_costs_20_seconds_and_changes_nothing() -> void:
	var attic := closed_attic()
	var result := Rules.try_code(attic, [3, 7, 4], CODE)
	assert_eq(result, {"correct": false, "penalty_seconds": 20, "error": ""}, "result")
	assert_eq(attic, closed_attic(), "still locked")


func test_not_three_dials_is_refused() -> void:
	assert_code_rejected(closed_attic(), [3, 7], "three")
	assert_code_rejected(closed_attic(), [3, 7, 5, 1], "three")


func test_dial_outside_1_to_9_is_refused() -> void:
	assert_code_rejected(closed_attic(), [0, 7, 5], "1 to 9")
	assert_code_rejected(closed_attic(), [3, 10, 5], "1 to 9")


func test_dial_that_is_not_a_whole_number_is_refused() -> void:
	assert_code_rejected(closed_attic(), [3, "7", 5], "1 to 9")
	assert_code_rejected(closed_attic(), [3, 7.5, 5], "1 to 9")


func test_trying_an_open_lock_is_refused() -> void:
	assert_code_rejected(open_attic(), [3, 7, 5], "already open")


# ---------- the choice ----------

func test_lock_in_gives_scary_christmas() -> void:
	var attic := open_attic()
	var result := Rules.choose(attic, "lock_in", false)
	assert_eq(result, {"ending": "scary", "error": ""}, "result")
	assert_eq(attic["choice"], "lock_in", "choice kept")


func test_reconcile_with_the_photo_gives_merry_christmas() -> void:
	var attic := open_attic()
	var result := Rules.choose(attic, "reconcile", true)
	assert_eq(result, {"ending": "merry", "error": ""}, "result")
	assert_eq(attic["choice"], "reconcile", "choice kept")


func test_reconcile_without_the_photo_is_refused() -> void:
	assert_choice_rejected(open_attic(), "reconcile", false, "nothing that could change his mind")


func test_choosing_before_the_lock_is_open_is_refused() -> void:
	assert_choice_rejected(closed_attic(), "lock_in", true, "locked")


func test_unknown_choice_is_refused() -> void:
	assert_choice_rejected(open_attic(), "run_away", true, "Unknown choice")


func test_second_choice_is_refused() -> void:
	var attic := open_attic()
	Rules.choose(attic, "lock_in", true)
	assert_choice_rejected(attic, "reconcile", true, "already")
