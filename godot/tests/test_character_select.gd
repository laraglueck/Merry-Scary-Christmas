# Tests for spec 18: the character selection screen (list left, big figure, arrows, Next).
extends "res://tests/base_test.gd"

const SelectScene = preload("res://scenes/character_select.tscn")


# A screen on its own (no network): plays all three players locally.
func open_select() -> Node:
	var screen = SelectScene.instantiate()
	tree.root.add_child(screen)
	return screen


func test_shows_the_list_the_big_figure_and_the_arrows() -> void:
	var screen := open_select()
	assert_contains(text_of(screen, "SelectTitle"), "Choose your character", "title")
	for character in ["santa", "snowman", "nutcracker"]:
		assert_true(find(screen, "Card_" + character) != null, character + " in the list")
	var big: TextureRect = find(screen, "Picture_big")
	assert_true(big != null and big.texture != null, "the big figure")
	for arrow in ["AccessoryPrev", "AccessoryNext", "ColourPrev", "ColourNext"]:
		assert_true(find(screen, arrow) != null, arrow)
	assert_true(find(screen, "NextButton") != null, "Next")


func test_everybody_starts_with_a_figure() -> void:
	var screen := open_select()
	assert_eq(screen.selection()[0], {"character": "santa", "colour": "red", "accessory": "none", "ready": false}, "red Santa first")
	assert_eq(is_disabled(screen, "NextButton"), false, "Next works at once")


func test_the_list_on_the_left_and_the_figure_beside_it() -> void:
	tree.root.size = Vector2i(1152, 648)
	var screen := open_select()
	await wait_frames(2)
	var card: Control = find(screen, "Card_santa")
	var big: Control = find(screen, "Picture_big")
	if card == null or big == null:
		return
	assert_true(card.get_global_rect().position.x < 60, "the list is at the left edge: %s" % card.get_global_rect())
	var centre_x: float = big.get_global_rect().get_center().x
	assert_true(centre_x > 576, "the figure is right of the middle: %d" % centre_x)
	assert_true(centre_x < 800, "but only a little: %d" % centre_x)
	assert_true(big.get_global_rect().size.y >= 350, "big: %s" % big.get_global_rect().size)
	var head_left: Control = find(screen, "AccessoryPrev")
	var head_right: Control = find(screen, "AccessoryNext")
	var hip_left: Control = find(screen, "ColourPrev")
	var hip_right: Control = find(screen, "ColourNext")
	assert_true(head_left.get_global_rect().end.x < big.get_global_rect().position.x + 40, "arrow left of the figure")
	assert_true(head_right.get_global_rect().position.x > big.get_global_rect().end.x - 40, "arrow right of the figure")
	assert_true(head_left.get_global_rect().position.y < hip_left.get_global_rect().position.y, "accessory arrows above the colour arrows")
	assert_true(absf(head_left.get_global_rect().position.y - head_right.get_global_rect().position.y) < 2, "a pair at the same height")
	assert_true(absf(hip_left.get_global_rect().position.y - hip_right.get_global_rect().position.y) < 2, "a pair at the same height")
	assert_true(screen.get_viewport().get_visible_rect().encloses(big.get_global_rect()), "everything on the screen")


func test_a_card_changes_the_figure_and_keeps_the_colour() -> void:
	var screen := open_select()
	press(screen, "ColourNext")  # green
	press(screen, "Card_snowman")
	assert_eq(screen.selection()[0]["character"], "snowman", "the snowman")
	assert_eq(screen.selection()[0]["colour"], "green", "still green")
	var big: TextureRect = find(screen, "Picture_big")
	if big != null:
		assert_true(big.texture.resource_path.ends_with("char_snowman_green.png"), "big picture: " + big.texture.resource_path)


func test_colour_arrows_page_through_the_colours() -> void:
	var screen := open_select()
	press(screen, "ColourNext")
	assert_eq(screen.selection()[0]["colour"], "green", "red -> green")
	press(screen, "ColourNext")
	assert_eq(screen.selection()[0]["colour"], "yellow", "green -> yellow")
	press(screen, "ColourNext")
	assert_eq(screen.selection()[0]["colour"], "red", "round again")
	press(screen, "ColourPrev")
	assert_eq(screen.selection()[0]["colour"], "yellow", "and back")


func test_accessory_arrows_are_a_placeholder() -> void:
	var screen := open_select()
	press(screen, "AccessoryNext")
	assert_eq(screen.selection()[0]["accessory"], "none", "nothing to choose yet")


func test_next_button_fits_on_the_screen() -> void:
	tree.root.size = Vector2i(1376, 768)
	var screen := open_select()
	await wait_frames(2)
	var next: Control = find(screen, "NextButton")
	if next != null:
		assert_true(screen.get_viewport().get_visible_rect().encloses(next.get_global_rect()), "Next fits: %s" % next.get_global_rect())


func test_taken_figure_and_colour_are_blocked_for_the_next_player() -> void:
	var screen := open_select()
	press(screen, "ColourNext")  # Player 1: red santa -> green santa
	press(screen, "Player2Button")
	assert_eq(screen.selection()[1]["character"], "snowman", "Player 2 starts with the first free figure")
	assert_eq(screen.selection()[1]["colour"], "red", "and the first free colour")
	assert_eq(is_disabled(screen, "Card_santa"), true, "santa is taken")
	assert_eq(is_disabled(screen, "Card_snowman"), false, "own figure stays free")
	assert_contains(text_of(screen, "Owner_santa"), "Player 1", "says who has it")
	press(screen, "ColourNext")  # red -> green is taken -> yellow
	assert_eq(screen.selection()[1]["colour"], "yellow", "green is skipped")


func test_waits_for_the_others_after_next() -> void:
	var screen := open_select()
	press(screen, "NextButton")
	assert_eq(screen.selection()[0]["ready"], true, "confirmed")
	assert_contains(text_of(screen, "WaitLabel"), "waiting for the others", "wait text")
	assert_eq(is_disabled(screen, "NextButton"), true, "no second press")
	assert_eq(is_disabled(screen, "ColourNext"), true, "no changes after confirming")
