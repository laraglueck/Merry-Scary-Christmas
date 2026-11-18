# Tests for spec 16: the end screen for Merry Christmas, Scary Christmas and Midnight.
extends "res://tests/base_test.gd"

const EndingScene = preload("res://scenes/ending.tscn")
const Settings = preload("res://scripts/settings.gd")


# Stands in for network.gd: only holds the finished game.
class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {}


# Opens the end screen like main.gd does: with the net and the phase as place.
func open_ending(phase: String, inventory: Array, seconds_used := 0) -> Node:
	var net := FakeNet.new()
	tree.root.add_child(net)
	net.game = {"phase": phase, "inventory": inventory, "seconds_played": seconds_used,
			"penalty_seconds": 0, "last_event": ""}
	var ending = EndingScene.instantiate()
	ending.net = net
	ending.place = phase
	tree.root.add_child(ending)
	return ending


func picture_of(ending: Node) -> String:
	return find(ending, "Background").texture.resource_path.get_file()


func test_merry_christmas_shows_its_title_and_picture() -> void:
	var ending := open_ending("merry", ["gift_1", "gift_2", "gift_3", "photo"])
	assert_eq(text_of(ending, "PlaceTitle"), "Merry Christmas!", "title")
	assert_eq(picture_of(ending), "ui_win_merry.webp", "picture")
	assert_contains(text_of(ending, "Line"), "remembered who he was", "line")


func test_scary_christmas_shows_its_title_and_picture() -> void:
	var ending := open_ending("scary", ["gift_1", "gift_2", "gift_3", "key"])
	assert_eq(text_of(ending, "PlaceTitle"), "Scary Christmas!", "title")
	assert_eq(picture_of(ending), "ui_win_scary.webp", "picture")
	assert_contains(text_of(ending, "Line"), "locked in", "line")


func test_midnight_shows_its_title_and_picture() -> void:
	var ending := open_ending("midnight", ["gift_2"], Settings.GAME_SECONDS)
	assert_eq(text_of(ending, "PlaceTitle"), "Midnight", "title")
	assert_eq(picture_of(ending), "ui_lose.webp", "picture")
	assert_contains(text_of(ending, "Line"), "struck twelve", "line")


func test_shows_the_presents_found() -> void:
	var ending := open_ending("scary", ["gift_1", "gift_3", "key"])
	assert_contains(text_of(ending, "Result"), "Presents found: 2 of 3", "presents")


func test_a_win_shows_the_time_left() -> void:
	var ending := open_ending("merry", ["photo"], 150)  # 600 - 150 = 450 s = 07:30
	assert_contains(text_of(ending, "Result"), "07:30 before midnight", "time left")


func test_midnight_shows_no_time_left() -> void:
	var ending := open_ending("midnight", [], Settings.GAME_SECONDS)
	assert_true(not text_of(ending, "Result").contains("before midnight"), "no time line")
