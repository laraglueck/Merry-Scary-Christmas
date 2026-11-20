extends "res://tests/base_test.gd"

const RoomScene = preload("res://scenes/bedroom.tscn")
const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")


func test_room_digit_appears_after_solving_and_stays_after_collection() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)

	var digit: Label = screen.find_child("RoomGoldDigit", true, false)
	assert_true(digit != null, "room digit exists")
	if digit == null:
		return

	assert_eq(digit.visible, false, "hidden before solving")

	var room: Dictionary = screen.offline_game["bedroom"]
	room["solved"] = true
	screen._update_room()

	var expected := str(BedroomRules.gold_digit(room))
	assert_eq(digit.visible, true, "visible after solving")
	assert_eq(digit.text, expected, "correct attic digit")
	assert_eq(
		digit.get_theme_color("font_color"),
		Color("ffd76a"),
		"gold colour"
	)

	screen._send("take_gift", {"room": "bedroom"})

	assert_eq(room["gift_taken"], true, "present collected")
	assert_eq(digit.visible, true, "digit remains visible")
	assert_eq(digit.text, expected, "digit unchanged")