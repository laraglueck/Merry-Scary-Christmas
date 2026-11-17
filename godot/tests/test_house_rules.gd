# Tests for spec 07: walking through the house (pure functions).
extends "res://tests/base_test.gd"

const HouseRules = preload("res://scripts/rules/house_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func light(game: Dictionary, fuse_index: int) -> void:
	var order: Array = game["puzzle"]["fuses"][fuse_index]["order"].duplicate()
	FuseRules.try_fuse(game["puzzle"], fuse_index, order)


func test_the_team_starts_in_the_hall() -> void:
	assert_eq(new_game().get("location"), "hall", "location")


func test_a_lit_room_can_be_entered() -> void:
	var game := new_game()
	light(game, 1)  # green: bathroom
	assert_eq(HouseRules.go_to(game, "bathroom"), "", "no error")
	assert_eq(game["location"], "bathroom", "location")


func test_a_dark_room_is_refused_with_a_reason() -> void:
	var game := new_game()
	var error := HouseRules.go_to(game, "bathroom")
	assert_contains(error, "still dark", "reason")
	assert_contains(error, "green fuse", "which fuse")
	assert_eq(game["location"], "hall", "still in the hall")


func test_from_a_room_only_back_to_the_hall() -> void:
	var game := new_game()
	light(game, 1)
	light(game, 2)
	HouseRules.go_to(game, "bathroom")
	assert_contains(HouseRules.go_to(game, "bedroom"), "hall first", "reason")
	assert_eq(game["location"], "bathroom", "still in the bathroom")
	assert_eq(HouseRules.go_to(game, "hall"), "", "back to the hall")
	assert_eq(game["location"], "hall", "location")


func test_the_attic_needs_all_three_fuses() -> void:
	var game := new_game()
	light(game, 0)
	light(game, 1)
	assert_contains(HouseRules.go_to(game, "attic"), "all three fuses", "reason with 2 fuses")
	assert_eq(game["location"], "hall", "still in the hall")
	light(game, 2)
	assert_eq(HouseRules.go_to(game, "attic"), "", "3 fuses: up the stairs")
	assert_eq(game["location"], "attic", "location")


func test_unknown_place_and_same_place_are_refused() -> void:
	var game := new_game()
	assert_contains(HouseRules.go_to(game, "kitchen"), "unknown place", "unknown")
	assert_contains(HouseRules.go_to(game, "hall"), "already", "same place")
	assert_eq(game["location"], "hall", "unchanged")


func test_place_names_for_messages() -> void:
	assert_eq(HouseRules.place_name("living_room"), "living/dining room", "living room")
	assert_eq(HouseRules.place_name("attic"), "attic", "attic")
