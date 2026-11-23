extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")


func game_with_key() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var game := GameRules.new_game(rng)
	game["location"] = "attic"
	game["attic"]["unlocked"] = true

	GameRules.apply(game, 0, "take_key", {})
	return game


func test_lock_in_requires_all_three_presents() -> void:
	var gifts := ["gift_1", "gift_2", "gift_3"]

	# Check all seven incomplete combinations of presents.
	for combination in range(7):
		var game := game_with_key()

		for i in range(3):
			if (combination & (1 << i)) != 0:
				InventoryRules.add(game, gifts[i])

		var attic_before: Dictionary = game["attic"].duplicate(true)
		var inventory_before: Array = game["inventory"].duplicate()

		GameRules.apply(game, 0, "choose_ending", {
			"choice": "lock_in",
		})

		assert_eq(game["phase"], "hall", "game continues")
		assert_eq(game["attic"], attic_before, "no ending chosen")
		assert_eq(game["inventory"], inventory_before, "items unchanged")
		assert_eq(game["penalty_seconds"], 0, "no penalty")
		assert_contains(game["last_event"], "presents", "reason given")


func test_lock_in_succeeds_with_key_and_all_presents() -> void:
	var game := game_with_key()

	for gift in ["gift_1", "gift_2", "gift_3"]:
		InventoryRules.add(game, gift)

	GameRules.apply(game, 0, "choose_ending", {
		"choice": "lock_in",
	})

	assert_eq(game["phase"], "scary", "Scary Christmas")
	assert_eq(game["attic"]["choice"], "lock_in", "choice remembered")
