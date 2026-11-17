# Tests for spec 14: the team's inventory (pure functions).
extends "res://tests/base_test.gd"

const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func test_five_items_in_a_fixed_order() -> void:
	var items: Array = Settings.ITEMS
	var ids := []
	for item in items:
		ids.append(item["id"])
	assert_eq(ids, ["gift_1", "gift_2", "gift_3", "photo", "key"], "the items")
	if items.size() == 5:
		assert_eq(items[3]["name"], "Photo", "a name to show")
		assert_eq(items[1]["picture"], "item_gift_2.png", "a picture to show")


func test_a_new_game_starts_with_an_empty_inventory() -> void:
	assert_eq(new_game().get("inventory"), [], "empty")


func test_an_item_goes_into_the_inventory() -> void:
	var game := new_game()
	assert_eq(InventoryRules.add(game, "gift_2"), "", "accepted")
	assert_eq(game["inventory"], ["gift_2"], "in the inventory")
	assert_eq(InventoryRules.has(game, "gift_2"), true, "the team has it")
	assert_eq(InventoryRules.has(game, "key"), false, "not the key")


func test_items_stay_in_the_order_they_were_found() -> void:
	var game := new_game()
	InventoryRules.add(game, "photo")
	InventoryRules.add(game, "gift_1")
	assert_eq(game["inventory"], ["photo", "gift_1"], "found order")


func test_an_item_only_once() -> void:
	var game := new_game()
	InventoryRules.add(game, "photo")
	assert_true(InventoryRules.add(game, "photo") != "", "second time refused")
	assert_eq(game["inventory"], ["photo"], "still once")


func test_an_unknown_item_is_refused() -> void:
	var game := new_game()
	assert_true(InventoryRules.add(game, "sword") != "", "refused")
	assert_eq(game["inventory"], [], "nothing changed")


func test_the_bathroom_present_goes_into_the_inventory() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "take_gift", {"room": "bathroom"})
	assert_eq(InventoryRules.has(game, "gift_2"), false, "not before the taps are solved")
	game["bathroom"]["solved"] = true
	GameRules.apply(game, 0, "take_gift", {"room": "bathroom"})
	assert_eq(game["inventory"], ["gift_2"], "now in the inventory")
	GameRules.apply(game, 1, "take_gift", {"room": "bathroom"})
	assert_eq(game["inventory"], ["gift_2"], "only once")
