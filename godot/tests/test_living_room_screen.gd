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
	var door: Node = screen.find_child("DoorHall", true, false)
	assert_true(door != null, "the door leads back (spec 24)")
	if door != null:
		door.pressed.emit()
	assert_eq(screen.game["location"], "hall", "the team walks back to the hall")


# Spec 24: the door, not a button, like in the bathroom.
func test_the_door_is_the_way_back_not_a_button() -> void:
	tree.root.size = Vector2i(1152, 648)
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	await wait_frames(2)
	assert_true(screen.find_child("BackButton", true, false) == null, "no Back to the hall button")
	var door: Button = screen.find_child("DoorHall", true, false)
	assert_true(door != null, "the door is a click area")
	if door != null:
		assert_true(Rect2(700, 130, 230, 320).encloses(door.get_global_rect()), "on the open door: %s" % door.get_global_rect())
		assert_eq(door.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "the hand on hover")
		assert_contains(door.tooltip_text, "hall", "the hint")
		assert_true(door.get_theme_stylebox("normal") is StyleBoxEmpty, "invisible until the mouse is over it")
		var hover = door.get_theme_stylebox("hover")
		assert_true(hover is StyleBoxFlat and hover.border_width_left > 0, "a frame on hover")


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


# Spec 24, after the manual test: every object shows a gold frame under the mouse.
func test_objects_show_a_gold_frame_on_hover() -> void:
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	for node_name in ["ClockButton", "NoteButton", "DoorHall"]:
		var button: Button = screen.find_child(node_name, true, false)
		assert_true(button != null, node_name + " exists")
		if button != null:
			assert_true(button.get_theme_stylebox("normal") is StyleBoxEmpty, node_name + ": invisible until hovered")
			var hover = button.get_theme_stylebox("hover")
			var gold: bool = hover is StyleBoxFlat and hover.border_width_left > 0 and hover.border_color.is_equal_approx(Color("ffd76a"))
			assert_true(gold, node_name + ": gold frame on hover")
			assert_eq(button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, node_name + ": hand cursor")


# Spec 24, after the manual test: the frames fit the clock and the poem exactly
# (measured on room_living_room_lit.webp on the 1152 x 648 stage).
func test_frames_fit_the_clock_and_the_poem() -> void:
	tree.root.size = Vector2i(1152, 648)
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	await wait_frames(2)
	var clock: Control = screen.find_child("ClockButton", true, false)
	if clock != null:
		var r := clock.get_global_rect()
		assert_true(r.encloses(Rect2(245, 125, 95, 370)), "covers the whole clock: %s" % r)
		assert_true(Rect2(225, 105, 135, 410).encloses(r), "not much bigger than the clock: %s" % r)
	var note: Control = screen.find_child("NoteButton", true, false)
	if note != null:
		var r := note.get_global_rect()
		assert_true(r.encloses(Rect2(995, 270, 48, 15)), "covers the poem: %s" % r)
		assert_true(Rect2(980, 255, 80, 42).encloses(r), "not much bigger than the poem: %s" % r)

