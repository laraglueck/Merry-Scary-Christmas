extends "res://tests/base_test.gd"

const RoomScene = preload("res://scenes/living_room.tscn")


func test_solving_clock_reveals_reward_and_gift_can_be_taken() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)

	var gift: TextureButton = screen.get_node("GiftButton")
	var digit: Label = screen.get_node("DigitLabel")
	var panel: Panel = screen.get_node("ClockPanel")

	assert_eq(gift.visible, false, "gift initially hidden")
	assert_eq(digit.visible, false, "digit initially hidden")

	screen.get_node("ClockButton").pressed.emit()
	assert_eq(panel.visible, true, "clock opens")

	var answer: Dictionary = screen.game["living_room"]
	screen._select_hand("short")
	screen._set_hand_position(answer["hour"])
	screen._select_hand("long")
	screen._set_hand_position(answer["minute"])

	screen.get_node("ClockPanel/TryClockButton").pressed.emit()

	assert_eq(answer["solved"], true, "clock solved")
	assert_eq(panel.visible, false, "close-up closes")
	assert_eq(gift.visible, true, "gift appears")
	assert_eq(digit.visible, true, "digit appears")
	assert_eq(digit.text, str(answer["digit"]), "correct attic digit")

	gift.pressed.emit()

	assert_eq(gift.visible, false, "collected gift disappears")
	assert_eq(screen.game["inventory"], ["gift_1"], "gift in inventory")
	assert_eq(digit.visible, true, "digit stays visible")


func test_note_reads_bathroom_answer_before_clock_is_solved() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)

	screen.game["bathroom"]["tap_order"] = ["hot", "cold", "cold", "hot"]
	screen.get_node("NoteButton").pressed.emit()

	assert_eq(screen.game["living_room"]["solved"], false, "clock still unsolved")
	assert_eq(screen.get_node("NotePanel").visible, true, "note opens")
	assert_eq(screen._note_text.text, "\n\n".join([
		"First, warm as fire burning bright,",
		"Then, cold as snow on Christmas night.",
		"Again, cold as the winds that blow,",
		"Last, warm as embers burning low.",
	]), "note uses the bathroom answer")
