# Tests for spec 16: the attic inside the shared game (GameRules.apply).
extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


# A game where the team already stands in the attic (walking there is spec 07's job).
func game_in_attic() -> Dictionary:
	var game := new_game()
	game["location"] = "attic"
	return game


func right_dials(game: Dictionary) -> Array:
	var dials: Array = AtticRules.code(game)
	if dials[2] == 0:
		dials[2] = 5  # no bedroom yet: any gold digit counts
	return dials


func wrong_dials(game: Dictionary) -> Array:
	var dials := right_dials(game)
	dials[0] = 1 if dials[0] != 1 else 2
	return dials


func game_with_attic_open() -> Dictionary:
	var game := game_in_attic()
	GameRules.apply(game, 0, "try_attic_code", {"dials": right_dials(game)})
	return game


func test_new_game_has_a_locked_attic() -> void:
	assert_eq(new_game().get("attic"), {"unlocked": false, "key_taken": false, "choice": ""}, "attic")


func test_right_code_opens_the_lock_for_everyone() -> void:
	var game := game_in_attic()
	GameRules.apply(game, 1, "try_attic_code", {"dials": right_dials(game)})
	assert_eq(game["attic"]["unlocked"], true, "unlocked")
	assert_contains(game["last_event"], "Player 2: the attic lock clicks open", "event")


func test_wrong_code_adds_20_seconds() -> void:
	var game := game_in_attic()
	GameRules.apply(game, 0, "try_attic_code", {"dials": wrong_dials(game)})
	assert_eq(game["attic"]["unlocked"], false, "still locked")
	assert_eq(game["penalty_seconds"], 20, "penalty")
	assert_contains(game["last_event"], "wrong code, -20 s", "event")


func test_refused_code_explains_why() -> void:
	var game := game_in_attic()
	GameRules.apply(game, 0, "try_attic_code", {"dials": [1, 2]})
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "three", "event")


func test_attic_actions_only_work_in_the_attic() -> void:
	var game := new_game()  # the team is in the hall
	GameRules.apply(game, 0, "try_attic_code", {"dials": right_dials(game)})
	assert_eq(game["attic"]["unlocked"], false, "still locked")
	assert_contains(game["last_event"], "climb up to the attic first", "event")


func test_lock_in_ends_the_game_as_scary_christmas_with_the_key() -> void:
	var game := game_with_attic_open()
	for gift in ["gift_1", "gift_2", "gift_3"]:
		InventoryRules.add(game, gift)

	GameRules.apply(game, 2, "take_key", {})
	assert_true(InventoryRules.has(game, "key"), "key in inventory")
	assert_contains(game["last_event"], "Player 3 took the key", "event")

	GameRules.apply(game, 2, "choose_ending", {"choice": "lock_in"})
	assert_eq(game["phase"], "scary", "phase")
	assert_true(InventoryRules.has(game, "key"), "key remains")
	assert_contains(game["last_event"], "Player 3 locked Scary Jingles in", "event")


func test_reconcile_with_the_photo_ends_the_game_as_merry_christmas() -> void:
	var game := game_with_attic_open()
	InventoryRules.add(game, "photo")
	InventoryRules.add(game, "cookies")  # spec 31
	GameRules.apply(game, 0, "choose_ending", {"choice": "reconcile"})
	assert_eq(game["phase"], "merry", "phase")
	assert_contains(game["last_event"], "left the photo and the cookies", "event")


func test_reconcile_without_the_photo_changes_nothing() -> void:
	var game := game_with_attic_open()
	GameRules.apply(game, 0, "choose_ending", {"choice": "reconcile"})
	assert_eq(game["phase"], "hall", "game goes on")
	assert_eq(game["attic"]["choice"], "", "nothing chosen")
	assert_contains(game["last_event"], "nothing that could change his mind", "event")


# Spec 31: the photo alone is not enough, the cookies belong to it.
func test_reconcile_with_the_photo_but_no_cookies_changes_nothing() -> void:
	var game := game_with_attic_open()
	InventoryRules.add(game, "photo")
	GameRules.apply(game, 0, "choose_ending", {"choice": "reconcile"})
	assert_eq(game["phase"], "hall", "game goes on")
	assert_eq(game["attic"]["choice"], "", "nothing chosen")
	assert_contains(game["last_event"], "cookies on the table", "points to the living room")


func test_choosing_before_the_lock_is_open_changes_nothing() -> void:
	var game := game_in_attic()
	GameRules.apply(game, 0, "choose_ending", {"choice": "lock_in"})
	assert_eq(game["phase"], "hall", "game goes on")
	assert_true(not InventoryRules.has(game, "key"), "no key")


func test_after_the_ending_nothing_changes() -> void:
	var game := game_with_attic_open()
	for gift in ["gift_1", "gift_2", "gift_3"]:
		InventoryRules.add(game, gift)
	GameRules.apply(game, 0, "take_key", {})
	GameRules.apply(game, 0, "choose_ending", {"choice": "lock_in"})
	assert_eq(game["phase"], "scary", "ending reached before checking")
	var before := game.duplicate(true)
	GameRules.apply(game, 0, "try_attic_code", {"dials": [1, 1, 1]})
	GameRules.apply(game, 0, "choose_ending", {"choice": "reconcile"})
	assert_eq(game, before, "game unchanged after the ending")


func test_a_game_saved_before_the_attic_existed_still_works() -> void:
	var game := game_in_attic()
	game.erase("attic")
	GameRules.apply(game, 0, "try_attic_code", {"dials": right_dials(game)})
	assert_eq(game["attic"]["unlocked"], true, "unlocked")


func test_lock_in_without_the_key_changes_nothing() -> void:
	var game := game_with_attic_open()
	GameRules.apply(game, 0, "choose_ending", {"choice": "lock_in"})
	assert_eq(game["phase"], "hall", "game goes on")
	assert_contains(game["last_event"], "key", "explains why")
