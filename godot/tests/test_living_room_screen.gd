extends "res://tests/base_test.gd"

const RoomScene = preload("res://scenes/living_room.tscn")
const Settings = preload("res://scripts/settings.gd")


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


# ---------- the window (spec 26) ----------

func open_window() -> Node:
	tree.root.size = Vector2i(1152, 648)
	var screen = RoomScene.instantiate()
	screen.seed_value = 42
	tree.root.add_child(screen)
	return screen


func test_the_window_is_a_click_area() -> void:
	var screen := open_window()
	await wait_frames(2)
	var window: Button = screen.find_child("WindowButton", true, false)
	assert_true(window != null, "the window can be clicked")
	if window != null:
		assert_true(window.get_global_rect().is_equal_approx(Rect2(44, 18, 160, 345)), "on the window: %s" % window.get_global_rect())
		assert_eq(window.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "the hand")
		assert_contains(window.tooltip_text, "window", "the hint")
		var hover = window.get_theme_stylebox("hover")
		assert_true(hover is StyleBoxFlat and hover.border_color.is_equal_approx(Color("ffd76a")), "gold frame")


func test_the_window_shows_the_outside() -> void:
	var screen := open_window()
	press(screen, "WindowButton")
	assert_eq(is_shown(screen, "WindowView"), true, "the view outside")
	var garden: Node = screen.find_child("GardenView", true, false)
	assert_true(garden != null and garden.texture != null and garden.texture.resource_path.ends_with("view_window_garden.png"), "the front garden with the moon in its sky")
	assert_true(screen.find_child("Moon", true, false) == null, "no moon on top: it is in the sky, behind the trees (made by tools/make_window_view.gd)")
	assert_contains(text_of(screen, "StoryLine"), "Santa's sleigh is flying tonight. Without Jingles.", "the story line")
	assert_eq(text_of(screen, "WeatherLine"), "Wiping the frost off the glass...", "first the glass is wiped")
	assert_eq(is_shown(screen, "Frost"), true, "frost on the glass")
	screen.find_child("WindowView", true, false).finish_wipe()
	assert_eq(text_of(screen, "WeatherLine"), "The glass is too frosted to read the thermometer.", "tests ask no service: the fallback")
	assert_eq(is_shown(screen, "Frost"), false, "the glass is clear")


func test_a_real_answer_shows_the_weather() -> void:
	var screen := open_window()
	press(screen, "WindowButton")
	var view: Node = screen.find_child("WindowView", true, false)
	var body := JSON.stringify({"current": {"temperature_2m": 3.2, "weather_code": 63}}).to_utf8_buffer()
	view._on_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body)
	assert_eq(text_of(screen, "WeatherLine"), "Wiping the frost off the glass...", "the answer waits until the glass is wiped")
	view.finish_wipe()
	assert_eq(text_of(screen, "WeatherLine"), "Nuuk, Greenland, tonight: 3 °C, rain.", "the real weather")
	var rain: CPUParticles2D = screen.find_child("WeatherRain", true, false)
	var snow: CPUParticles2D = screen.find_child("WeatherSnow", true, false)
	assert_true(rain != null and rain.emitting, "it rains outside")
	assert_true(snow == null or not snow.emitting, "and does not snow")


func test_no_internet_shows_the_fallback() -> void:
	var screen := open_window()
	press(screen, "WindowButton")
	var view: Node = screen.find_child("WindowView", true, false)
	view.finish_wipe()
	view._on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	assert_eq(text_of(screen, "WeatherLine"), "The glass is too frosted to read the thermometer.", "fallback, at once after the wipe")
	var snow: CPUParticles2D = screen.find_child("WeatherSnow", true, false)
	assert_true(snow != null and snow.emitting, "it snows anyway")


func test_the_window_view_closes_and_changes_nothing() -> void:
	var screen := open_window()
	var before: Dictionary = screen.game.duplicate(true)
	press(screen, "WindowButton")
	key_press("ui_cancel")
	assert_eq(is_shown(screen, "WindowView"), false, "Esc closes it")
	press(screen, "WindowButton")
	key_press("ui_accept")
	assert_eq(is_shown(screen, "WindowView"), false, "Enter closes it")
	assert_eq(screen.game, before, "nothing changed in the game")


func key_press(action: String) -> void:
	for down in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		tree.root.push_input(event)


func is_shown(screen: Node, node_name: String) -> bool:
	var node := screen.find_child(node_name, true, false)
	return node != null and node.is_visible_in_tree()


func test_the_window_view_covers_the_room_and_a_click_closes_it() -> void:
	var screen := open_window()
	await wait_frames(2)
	press(screen, "WindowButton")
	await wait_frames(2)
	var view: Control = screen.find_child("WindowView", true, false)
	assert_true(view != null and view.get_global_rect().encloses(Rect2(0, 0, 1152, 648)), "covers the whole room: %s" % (view.get_global_rect() if view != null else Rect2()))
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = Vector2(600, 300)
		click.global_position = Vector2(600, 300)
		tree.root.push_input(click)
	assert_eq(is_shown(screen, "WindowView"), false, "a click closes it")


# After the manual test: the frost is wiped off slowly, so there is time to read the line.
func test_the_frost_is_wiped_off_from_left_to_right() -> void:
	assert_true(Settings.WINDOW_WIPE_SECONDS >= 2.0, "time to read 'Wiping the frost...'")
	var screen := open_window()
	press(screen, "WindowButton")
	await wait_frames(2)
	var view: Node = screen.find_child("WindowView", true, false)
	var frost: Control = screen.find_child("Frost", true, false)
	var glass: Control = screen.find_child("Glass", true, false)
	view.wipe = 0.0
	assert_true(frost.get_global_rect().position.x <= glass.get_global_rect().position.x + 1, "all frosty at first")
	view.wipe = 0.5
	var half: float = glass.get_global_rect().position.x + glass.size.x * 0.5
	assert_true(absf(frost.get_global_rect().position.x + 80 - half) < 2, "half wiped: the frost starts in the middle")


# Third manual test: rain, storm and clouds must look like it.
func view_with_weather(code: int) -> Array:
	var screen := open_window()
	press(screen, "WindowButton")
	var view: Node = screen.find_child("WindowView", true, false)
	view.finish_wipe()
	var body := JSON.stringify({"current": {"temperature_2m": -2.0, "weather_code": code}}).to_utf8_buffer()
	view._on_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body)
	return [screen, view]


func garden_file(screen: Node) -> String:
	var garden: Node = screen.find_child("GardenView", true, false)
	return garden.texture.resource_path.get_file() if garden != null and garden.texture != null else ""


func test_rain_falls_in_streaks_under_a_dark_sky() -> void:
	var screen: Node = view_with_weather(61)[0]
	var rain: CPUParticles2D = screen.find_child("WeatherRain", true, false)
	assert_true(rain != null and rain.emitting and rain.texture != null, "drops with a picture, not dots")
	assert_true(rain != null and rain.particle_flag_align_y, "the streaks point the way they fall")
	assert_eq(is_shown(screen, "WeatherTint"), true, "a darker sky")
	assert_eq(garden_file(screen), "view_window_garden.png", "the moon still shines, as with snow")


func test_a_storm_drives_the_snow_sideways() -> void:
	var screen: Node = view_with_weather(95)[0]
	var storm: CPUParticles2D = screen.find_child("WeatherStorm", true, false)
	assert_true(storm != null and storm.emitting, "storm snow")
	assert_true(storm != null and storm.gravity.x > 100 and storm.amount >= 300, "dense and blown by the wind")
	var snow: CPUParticles2D = screen.find_child("WeatherSnow", true, false)
	assert_true(snow == null or not snow.emitting, "not the calm snow")
	assert_eq(is_shown(screen, "WeatherTint"), true, "a darker sky")
	assert_eq(garden_file(screen), "view_window_garden.png", "the moon still shines, as with snow")


func test_the_moon_is_pale_behind_clouds_and_bright_on_clear_nights() -> void:
	for pair in [[0, "view_window_garden.png"], [73, "view_window_garden.png"], [3, "view_window_garden_cloudy.png"],
			[45, "view_window_garden_cloudy.png"]]:
		var screen: Node = view_with_weather(pair[0])[0]
		assert_eq(garden_file(screen), pair[1], "code %d" % pair[0])
		var shows_tint: bool = is_shown(screen, "WeatherTint")
		assert_eq(shows_tint, false, "no dark sky for code %d" % pair[0])
		screen.free()

