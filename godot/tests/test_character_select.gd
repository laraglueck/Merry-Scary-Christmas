# Tests for spec 18: the character selection screen (list left, big figure, arrows, Next).
extends "res://tests/base_test.gd"
const Settings = preload("res://scripts/settings.gd")

const SelectScene = preload("res://scenes/character_select.tscn")


# A screen on its own (no network): plays all three players locally. Nobody has a hero
# yet (free choice), so most tests let Player 1 take Santa first.
func open_select(pick := "santa") -> Node:
	var screen = SelectScene.instantiate()
	tree.root.add_child(screen)
	if pick != "":
		press(screen, "Card_" + pick)
	return screen


func test_shows_the_list_the_big_figure_and_the_arrows() -> void:
	var screen := open_select()
	assert_contains(text_of(screen, "SelectTitle"), "Choose your character", "title")
	for character in ["santa", "snowman", "nutcracker"]:
		assert_true(find(screen, "Card_" + character) != null, character + " in the list")
	var big: TextureRect = find(screen, "Picture_big")
	assert_true(big != null and big.texture != null, "the big figure, once a hero is chosen")
	for arrow in ["AccessoryPrev", "AccessoryNext", "ColourPrev", "ColourNext"]:
		assert_true(find(screen, arrow) != null, arrow)
	assert_true(find(screen, "NextButton") != null, "Next")


# Free choice (second test round): nobody gets a hero by themselves.
func test_nobody_has_a_hero_until_they_choose() -> void:
	var screen := open_select("")
	assert_true(not screen.selection().has(0), "no hero yet")
	assert_eq(is_disabled(screen, "NextButton"), true, "Next only after choosing")
	assert_contains(text_of(screen, "ChooseHint"), "Choose your hero", "says what to do")
	press(screen, "Card_snowman")
	assert_eq(screen.selection()[0]["character"], "snowman", "the snowman, chosen freely")
	assert_eq(is_disabled(screen, "NextButton"), false, "now Next works")


# Playtest: the power text ran out of the bottom of the card.
func test_the_power_text_fits_inside_the_card() -> void:
	var screen := open_select()
	await tree.process_frame
	for info in Settings.CHARACTERS:
		var card: Control = screen.find_child("Card_" + info["id"], true, false)
		var power: Label = screen.find_child("Power_" + info["id"], true, false)
		var texts: Control = power.get_parent()
		assert_true(texts.get_combined_minimum_size().y <= card.size.y - 12,
			"%s: text %d high, card %d" % [info["id"], texts.get_combined_minimum_size().y, card.size.y])


func test_every_card_and_the_chosen_hero_show_the_power() -> void:
	var screen := open_select("")
	for character in ["santa", "snowman", "nutcracker"]:
		assert_true(text_of(screen, "Power_" + character) != "", character + " shows its power")
	press(screen, "Card_nutcracker")
	assert_contains(text_of(screen, "PowerLabel"), "Crack", "the chosen hero's power under the figure")


func test_a_taken_hero_is_free_again_when_its_player_changes() -> void:
	var screen := open_select()  # Player 1: Santa
	press(screen, "Player2Button")
	assert_eq(is_disabled(screen, "Card_santa"), true, "Santa is taken")
	press(screen, "Player1Button")
	press(screen, "Card_snowman")  # Player 1 changes their mind
	press(screen, "Player2Button")
	assert_eq(is_disabled(screen, "Card_santa"), false, "Santa is free again")


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


# Spec 27: the accessory arrows switch the accessory, and the big figure shows it.
func test_accessory_arrows_change_the_big_figure() -> void:
	var screen := open_select()
	press(screen, "AccessoryNext")
	assert_eq(screen.selection()[0]["accessory"], "bow", "none -> bow")
	assert_eq(big_picture(screen), "char_santa_bow.png", "Santa wears the bow")
	assert_contains(text_of(screen, "AccessoryLabel"), "Bow", "label")
	press(screen, "AccessoryPrev")
	press(screen, "AccessoryPrev")
	assert_eq(screen.selection()[0]["accessory"], "antlers", "none <- antlers")
	assert_eq(big_picture(screen), "char_santa_antlers.png", "Santa wears antlers")


func test_accessory_stays_when_colour_or_figure_changes() -> void:
	var screen := open_select()
	press(screen, "AccessoryNext")
	press(screen, "AccessoryNext")
	press(screen, "ColourNext")
	assert_eq(big_picture(screen), "char_santa_green_nose.png", "green Santa, still the red nose")
	press(screen, "Card_snowman")
	assert_eq(big_picture(screen), "char_snowman_green_nose.png", "the snowman takes over colour and nose")
	assert_eq(card_picture(screen, "snowman"), "char_snowman_green_nose.png", "the card shows it too")


func big_picture(screen: Node) -> String:
	var big: TextureRect = find(screen, "Picture_big")
	return big.texture.resource_path.get_file() if big != null and big.texture != null else ""


func card_picture(screen: Node, character: String) -> String:
	var picture: TextureRect = find(screen, "Picture_" + character)
	return picture.texture.resource_path.get_file() if picture != null and picture.texture != null else ""


func test_next_button_fits_on_the_screen() -> void:
	tree.root.size = Vector2i(1376, 768)
	var screen := open_select()
	await wait_frames(2)
	var next: Control = find(screen, "NextButton")
	if next != null:
		assert_true(screen.get_viewport().get_visible_rect().encloses(next.get_global_rect()), "Next fits: %s" % next.get_global_rect())


# Playtest: a taken hero is clearly greyed out.
func test_a_taken_hero_is_clearly_greyed_out() -> void:
	var screen := open_select()  # Player 1: Santa
	press(screen, "Player2Button")
	var card: Control = screen.find_child("Card_santa", true, false)
	assert_true(card.modulate.a <= 0.4, "faded: %s" % card.modulate.a)
	assert_eq(screen.find_child("Card_snowman", true, false).modulate.a, 1.0, "a free hero is not")


# Playtest: clicking your own hero again gives it back, so the others can swap.
func test_clicking_your_own_hero_again_gives_it_back() -> void:
	var screen := open_select()  # Player 1: Santa
	press(screen, "Card_santa")
	assert_eq(screen.selection().has(0), false, "Player 1 has no hero now")
	assert_eq(is_disabled(screen, "Card_santa"), false, "Santa is free")
	assert_eq(screen.find_child("ChooseHint", true, false).visible, true, "asks to choose again")


func test_taken_figure_is_blocked_but_colours_are_shared() -> void:
	var screen := open_select()
	press(screen, "ColourNext")  # Player 1: red santa -> green santa
	press(screen, "Player2Button")
	press(screen, "Card_snowman")
	assert_eq(screen.selection()[1]["character"], "snowman", "Player 2 chose the snowman")
	assert_eq(is_disabled(screen, "Card_santa"), true, "santa is taken")
	assert_eq(is_disabled(screen, "Card_snowman"), false, "own figure stays free")
	assert_contains(text_of(screen, "Owner_santa"), "Player 1", "says who has it")
	press(screen, "ColourNext")  # red -> green, even though Player 1 is green
	assert_eq(screen.selection()[1]["colour"], "green", "green twice is fine")
	assert_contains(text_of(screen, "ColourLabel"), "Green", "shows the colour")


# With all three players on screen, the colour arrows still change the colour.
func test_colour_arrows_work_with_three_players() -> void:
	var screen := open_select()
	press(screen, "Player2Button")
	press(screen, "Card_snowman")
	press(screen, "Player3Button")
	press(screen, "Card_nutcracker")
	assert_eq(screen.selection().size(), 3, "all three have a figure")
	var before: String = screen.selection()[2]["colour"]
	press(screen, "ColourNext")
	assert_true(screen.selection()[2]["colour"] != before, "the colour changed: %s" % screen.selection()[2]["colour"])


func test_waits_for_the_others_after_next() -> void:
	var screen := open_select()
	press(screen, "NextButton")
	assert_eq(screen.selection()[0]["ready"], true, "confirmed")
	assert_contains(text_of(screen, "WaitLabel"), "waiting for the others", "wait text")
	assert_eq(is_disabled(screen, "NextButton"), true, "no second press")
	assert_eq(is_disabled(screen, "ColourNext"), true, "no changes after confirming")
