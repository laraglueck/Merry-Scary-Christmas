extends "res://tests/base_test.gd"

const RoomScene = preload("res://scenes/living_room.tscn")


func test_solving_clock_reveals_reward_and_gift_can_be_taken() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)

	var gift: TextureButton = screen.find_child("GiftButton", true, false)
	var digit: Label = screen.find_child("DigitLabel", true, false)
	var panel: Panel = screen.find_child("ClockPanel", true, false)

	assert_eq(gift.visible, false, "gift initially hidden")
	assert_eq(digit.visible, false, "digit initially hidden")

	screen.find_child("ClockButton", true, false).pressed.emit()
	assert_eq(panel.visible, true, "clock opens")

	var answer: Dictionary = screen.game["living_room"]
	screen._select_hand("short")
	screen._set_hand_position(answer["hour"])
	screen._select_hand("long")
	screen._set_hand_position(answer["minute"])

	screen.find_child("TryClockButton", true, false).pressed.emit()

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
	screen.find_child("NoteButton", true, false).pressed.emit()

	assert_eq(screen.game["living_room"]["solved"], false, "clock still unsolved")
	assert_eq(screen.find_child("NotePanel", true, false).visible, true, "note opens")
	assert_eq(screen._note_text.text, "\n\n".join([
		"First, warm as fire burning bright,",
		"Then, cold as snow on Christmas night.",
		"Again, cold as the winds that blow,",
		"Last, warm as embers burning low.",
	]), "note uses the bathroom answer")


func test_back_to_the_hall() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	screen.find_child("BackButton", true, false).pressed.emit()
	assert_eq(screen.game["location"], "hall", "the team walks back to the hall")


# Spec 21: a torn piece of the photo lies in the opened clock.
func test_a_torn_piece_lies_in_the_open_clock() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	var piece: TextureButton = screen.find_child("PhotoPiece", true, false)
	assert_eq(piece.visible, false, "not before the clock opens")
	var answer: Dictionary = screen.game["living_room"]
	screen._select_hand("short")
	screen._set_hand_position(answer["hour"])
	screen._select_hand("long")
	screen._set_hand_position(answer["minute"])
	screen.find_child("TryClockButton", true, false).pressed.emit()
	assert_eq(piece.visible, true, "in the open clock")
	piece.pressed.emit()
	assert_true("photo_piece_1" in screen.game["inventory"], "in the inventory")
	assert_eq(piece.visible, false, "taken")


# Spec 21: tidier and resizable.
func test_the_living_room_scales_and_has_no_name_labels() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	screen.size = Vector2(576, 324)
	var stage: Control = screen.find_child("Stage", true, false)
	assert_true(stage != null and stage.scale == Vector2(0.5, 0.5), "scales as a whole")
	assert_eq(screen.find_child("NoteButton", true, false).text, "", "no 'Read note' label")
