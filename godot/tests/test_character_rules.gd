# Tests for spec 18: the rules of the character selection (pure functions).
extends "res://tests/base_test.gd"

const CharacterRules = preload("res://scripts/rules/character_rules.gd")


func test_a_pick_is_saved_and_not_ready() -> void:
	var selection := {}
	assert_eq(CharacterRules.pick(selection, 0, "santa", "green"), "", "allowed")
	assert_eq(selection[0], {"character": "santa", "colour": "green", "accessory": "none", "ready": false}, "saved")


func test_unknown_character_or_colour_is_refused() -> void:
	var selection := {}
	assert_contains(CharacterRules.pick(selection, 0, "elf", "red"), "unknown character", "character")
	assert_contains(CharacterRules.pick(selection, 0, "santa", "pink"), "unknown colour", "colour")
	assert_eq(selection, {}, "nothing changed")


func test_a_taken_character_is_refused() -> void:
	var selection := {}
	CharacterRules.pick(selection, 0, "santa", "red")
	assert_contains(CharacterRules.pick(selection, 1, "santa", "green"), "taken by Player 1", "character")
	assert_eq(selection.has(1), false, "Player 2 has nothing yet")


# Spec 18, change: two players may share a colour, the figures tell them apart.
func test_a_colour_can_be_shared() -> void:
	var selection := {}
	CharacterRules.pick(selection, 0, "santa", "red")
	assert_eq(CharacterRules.pick(selection, 1, "snowman", "red"), "", "red twice is fine")
	assert_eq(selection[1]["colour"], "red", "Player 2 is red too")


func test_a_player_can_change_their_own_pick() -> void:
	var selection := {}
	CharacterRules.pick(selection, 0, "santa", "red")
	assert_eq(CharacterRules.pick(selection, 0, "santa", "yellow"), "", "same character, new colour")
	assert_eq(selection[0]["colour"], "yellow", "new colour")
	assert_eq(CharacterRules.pick(selection, 0, "snowman", "yellow"), "", "new character")
	assert_eq(CharacterRules.pick(selection, 1, "santa", "red"), "", "the old ones are free again")


func test_unknown_player_is_refused() -> void:
	var selection := {}
	assert_contains(CharacterRules.pick(selection, 3, "santa", "red"), "unknown player", "player")
	assert_eq(selection, {}, "nothing changed")


func test_ready_needs_a_pick_and_a_new_pick_resets_it() -> void:
	var selection := {}
	assert_contains(CharacterRules.set_ready(selection, 0), "choose a character", "no pick")
	CharacterRules.pick(selection, 0, "santa", "red")
	assert_eq(CharacterRules.set_ready(selection, 0), "", "ready")
	assert_eq(selection[0]["ready"], true, "marked ready")
	CharacterRules.pick(selection, 0, "santa", "green")
	assert_eq(selection[0]["ready"], false, "changing the pick is not ready any more")


func test_all_ready_needs_all_three_players() -> void:
	var selection := {}
	var picks := [["santa", "red"], ["snowman", "green"], ["nutcracker", "yellow"]]
	for player in 3:
		assert_eq(CharacterRules.all_ready(selection), false, "not yet (%d ready)" % player)
		CharacterRules.pick(selection, player, picks[player][0], picks[player][1])
		CharacterRules.set_ready(selection, player)
	assert_eq(CharacterRules.all_ready(selection), true, "all three ready")


func test_first_free_colour_skips_the_taken_ones() -> void:
	var selection := {}
	assert_eq(CharacterRules.first_free_colour(selection, 0), "red", "red first")
	CharacterRules.pick(selection, 1, "santa", "red")
	assert_eq(CharacterRules.first_free_colour(selection, 0), "green", "red is taken")
	assert_eq(CharacterRules.first_free_colour(selection, 1), "red", "my own colour counts as free")


func test_picture_file_follows_the_asset_names() -> void:
	assert_eq(CharacterRules.picture_file("santa", "red"), "char_santa.png", "red = the plain picture")
	assert_eq(CharacterRules.picture_file("snowman", "green"), "char_snowman_green.png", "green")
	assert_eq(CharacterRules.picture_file("nutcracker", "yellow"), "char_nutcracker_yellow.png", "yellow")


func test_all_nine_pictures_exist() -> void:
	for character in CharacterRules.character_ids():
		for colour in CharacterRules.colour_ids():
			var file := "res://assets/images/" + CharacterRules.picture_file(character, colour)
			assert_true(ResourceLoader.exists(file), file + " exists")


func test_final_characters_drop_the_ready_flag() -> void:
	var selection := {}
	CharacterRules.pick(selection, 0, "santa", "red")
	CharacterRules.set_ready(selection, 0)
	assert_eq(CharacterRules.final_characters(selection), {0: {"character": "santa", "colour": "red", "accessory": "none"}}, "only the choice")


func test_unknown_accessory_is_refused() -> void:
	var selection := {}
	assert_contains(CharacterRules.pick(selection, 0, "santa", "red", "top_hat"), "unknown accessory", "accessory")
	assert_eq(selection, {}, "nothing changed")


func test_next_colour_goes_round_through_all_colours() -> void:
	var selection := {}
	CharacterRules.pick(selection, 0, "santa", "red")
	assert_eq(CharacterRules.next_colour(selection, 0, 1), "green", "red -> green")
	assert_eq(CharacterRules.next_colour(selection, 0, -1), "yellow", "red <- yellow (round)")
	CharacterRules.pick(selection, 1, "snowman", "green")
	CharacterRules.pick(selection, 2, "nutcracker", "yellow")
	assert_eq(CharacterRules.next_colour(selection, 0, 1), "green", "all taken: still changes (shared)")


func test_next_accessory_goes_round() -> void:
	var first: String = CharacterRules.accessory_ids()[0]
	assert_eq(CharacterRules.next_accessory(first, 1) in CharacterRules.accessory_ids(), true, "a known accessory")
	assert_eq(CharacterRules.next_accessory("none", 1), "none", "only the placeholder: stays")
