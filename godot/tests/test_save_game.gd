# Tests for spec 15: saving the shared game and loading it back.
extends "res://tests/base_test.gd"

const SaveGame = preload("res://scripts/save_game.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const Settings = preload("res://scripts/settings.gd")


# A game in the middle: 95 s played, 20 s penalty, bathroom lit, the team in it, Present 2 found.
func a_played_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var game := GameRules.new_game(rng)
	ClockRules.tick(game, 95)
	game["penalty_seconds"] = 20
	game["puzzle"]["fuses"][1]["solved"] = true
	game["location"] = "bathroom"
	InventoryRules.add(game, "gift_2")
	return game


func test_tests_never_touch_the_real_save() -> void:
	assert_true(SaveGame.path() != Settings.SAVE_PATH, "a test file, not the real save: %s" % SaveGame.path())
	assert_true(SaveGame.path().begins_with("user://"), "in Godot's data folder")


func test_a_saved_game_loads_back_unchanged() -> void:
	var game := a_played_game()
	SaveGame.save(game, SaveGame.path())
	var loaded := SaveGame.load_from(SaveGame.path())
	assert_eq(loaded, game, "the same game")
	assert_eq(typeof(loaded.get("seconds_played")), TYPE_INT, "numbers stay whole numbers")
	assert_eq(ClockRules.time_left(loaded), 485, "the same time left")


func test_no_save_loads_as_empty() -> void:
	assert_eq(SaveGame.exists(SaveGame.path()), false, "nothing saved yet")
	assert_eq(SaveGame.load_from(SaveGame.path()), {}, "empty")


func test_a_broken_save_loads_as_empty() -> void:
	var file := FileAccess.open(SaveGame.path(), FileAccess.WRITE)
	file.store_string("this is not a game")
	file.close()
	assert_eq(SaveGame.load_from(SaveGame.path()), {}, "broken file: empty")
	assert_eq(SaveGame.exists(SaveGame.path()), false, "nothing to resume")


func test_remove_deletes_the_save() -> void:
	SaveGame.save(a_played_game(), SaveGame.path())
	assert_eq(SaveGame.exists(SaveGame.path()), true, "saved")
	SaveGame.remove(SaveGame.path())
	assert_eq(SaveGame.exists(SaveGame.path()), false, "gone")
