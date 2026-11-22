# Tests for the hero powers: each hero has one power, once per game.
extends "res://tests/base_test.gd"

const PowerRules = preload("res://scripts/rules/power_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func game_with(heroes: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var characters := {}
	for i in heroes.size():
		characters[i] = {"character": heroes[i], "colour": "red", "accessory": "none"}
	return GameRules.new_game(rng, characters)


func test_each_hero_has_their_own_power() -> void:
	var game := game_with(["santa", "snowman", "nutcracker"])
	assert_eq(PowerRules.power_of(game, 0), "hint", "Santa")
	assert_eq(PowerRules.power_of(game, 1), "freeze", "Snowman")
	assert_eq(PowerRules.power_of(game, 2), "crack", "Nutcracker")


func test_santa_gives_a_hint_for_the_room() -> void:
	var game := game_with(["santa"])
	game["location"] = "bathroom"
	assert_eq(PowerRules.use(game, 0), "", "used")
	assert_contains(game["last_event"], "rhyme", "a tip about the bathroom")


# Santa's tip says what to do next: it changes with the team's progress.
func test_santa_says_what_comes_next() -> void:
	var game := game_with(["santa"])
	game["location"] = "bathroom"
	game["bathroom"]["solved"] = true
	assert_contains(PowerRules.hint_for(game), "chest", "taps done: the mirror's symbols are for the chest")
	game["location"] = "attic"
	game["attic"]["unlocked"] = true
	assert_contains(PowerRules.hint_for(game), "key", "lock open: take the key")
	game["attic"]["key_taken"] = true
	assert_contains(PowerRules.hint_for(game), "photo", "then think of the photo")
	assert_contains(PowerRules.hint_for(game), "cookies", "and of the cookies (spec 31)")
	game["location"] = "hall"
	for fuse in game["puzzle"]["fuses"]:
		fuse["solved"] = true
	assert_contains(PowerRules.hint_for(game), "living room", "all lit: start with the first unsolved room")


func test_the_snowman_freezes_the_clock() -> void:
	var game := game_with(["santa", "snowman"])
	var before := ClockRules.time_left(game)
	PowerRules.use(game, 1)
	assert_eq(ClockRules.time_left(game), before + Settings.FREEZE_SECONDS, "30 seconds more")


func test_the_nutcracker_cracks_one_part_of_the_answer() -> void:
	var game := game_with(["santa", "snowman", "nutcracker"])
	game["location"] = "living_room"
	PowerRules.use(game, 2)
	assert_contains(game["last_event"], "short hand points to %d" % game["living_room"]["hour"], "part of the clock")


func test_a_power_works_once_per_game() -> void:
	var game := game_with(["santa"])
	assert_eq(PowerRules.use(game, 0), "", "first time")
	assert_contains(PowerRules.use(game, 0), "already", "second time refused")
	assert_eq(PowerRules.is_used(game, 0), true, "remembered")


func test_no_power_without_a_hero() -> void:
	var game := game_with([])
	assert_contains(PowerRules.use(game, 0), "hero", "refused")


func test_use_power_through_the_game_and_after_saving() -> void:
	var game := game_with(["santa", "snowman"])
	game["characters"] = JSON.parse_string(JSON.stringify(game["characters"]))  # a saved game has text keys
	GameRules.apply(game, 1, "use_power", {})
	assert_contains(game["last_event"], "Player 2", "who used it")
	assert_contains(game["last_event"], "Freeze", "which power")
