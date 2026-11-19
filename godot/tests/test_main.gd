# Tests for spec 04: the main scene switches between lobby and hall.
extends "res://tests/base_test.gd"

const MainScene = preload("res://scenes/main.tscn")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const Settings = preload("res://scripts/settings.gd")


# One device running the whole game (main scene), with its own multiplayer.
func make_main_device(device_name: String) -> Node:
	var device := Node.new()
	device.name = device_name
	tree.root.add_child(device)
	tree.set_multiplayer(SceneMultiplayer.new(), device.get_path())
	var main = MainScene.instantiate()
	device.add_child(main)
	return main


# Three devices with the main scene; host creates, two join, host starts.
func make_started_mains(port: int) -> Array:
	var host := make_main_device("Host")
	var a := make_main_device("A")
	var b := make_main_device("B")
	if host.net == null:
		return [host, a, b]
	host.net.host_room(port)
	a.net.join_room("127.0.0.1", port)
	await wait_until(func(): return a.net.connected)
	b.net.join_room("127.0.0.1", port)
	await wait_until(func(): return b.net.connected)
	await wait_until(func(): return host.net.players.size() == 3)
	host.net.start_game()
	return [host, a, b]


func test_main_starts_with_the_story() -> void:
	var main := make_main_device("Solo")
	assert_eq(main.screen_name, "intro", "the story first, before the title (spec 25)")
	await wait_frames(2)
	assert_true(main.find_child("SubtitleLabel", true, false) != null, "story shown")
	assert_true(main.find_child("StartButton", true, false) == null, "no title yet")


func test_main_story_then_title_then_lobby() -> void:
	var main := make_main_device("Solo2")
	main.screen.finished.emit()  # voice over, click or key
	assert_eq(main.screen_name, "title", "the title after the story")
	await wait_frames(2)
	assert_true(main.find_child("SubtitleLabel", true, false) == null, "story gone")
	press(main, "StartButton")
	assert_eq(main.screen_name, "lobby", "lobby after Start")
	await wait_frames(2)  # the old screens are removed at the end of a frame
	assert_true(main.find_child("CreateButton", true, false) != null, "lobby shown")
	assert_true(main.find_child("TitleLabel", true, false) == null, "title gone")
	assert_true(main.find_child("SubtitleLabel", true, false) == null, "story gone")


func test_menu_music_only_on_the_title() -> void:
	var main := make_main_device("Solo3")
	var music: AudioStreamPlayer = main.get_node_or_null("Music")
	assert_true(music != null and music.stream != null, "music in main")
	assert_true(music != null and music.stream.loop, "music loops")
	assert_eq(main.get("menu_music_on"), false, "no music under the story")
	main.screen.finished.emit()
	assert_eq(main.get("menu_music_on"), true, "music on the title")
	press(main, "StartButton")
	assert_eq(main.get("menu_music_on"), false, "quiet from the lobby on (spec 23)")


func test_main_switches_everyone_to_the_hall_when_the_game_starts() -> void:
	var mains: Array = await make_started_mains(47551)
	var all_in_hall := func(): return mains.all(func(m): return m.screen_name == "hall")
	assert_true(await wait_until(all_in_hall), "all three show the hall")
	await wait_frames(2)  # the old lobby is removed at the end of a frame
	assert_true(mains[1].find_child("CreateButton", true, false) == null, "lobby gone on Player 2")
	assert_contains(text_of(mains[1], "FuseTitle"), "GREEN", "Player 2 plays the green fuse")


func test_main_shows_the_character_selection_before_the_game() -> void:
	var host := make_main_device("SelHost")
	var a := make_main_device("SelA")
	var b := make_main_device("SelB")
	host.net.host_room(47553)
	a.net.join_room("127.0.0.1", 47553)
	await wait_until(func(): return a.net.connected)
	b.net.join_room("127.0.0.1", 47553)
	await wait_until(func(): return b.net.connected)
	await wait_until(func(): return host.net.players.size() == 3)
	var mains := [host, a, b]
	host.net.begin_selection()
	assert_true(await wait_until(func(): return mains.all(func(m): return m.screen_name == "select")), "all three choose")
	await wait_frames(2)
	assert_true(a.find_child("Card_santa", true, false) != null, "selection screen on Player 2")
	assert_eq(a.get("menu_music_on"), false, "no menu music after the title (spec 23)")
	var picks := [["santa", "red"], ["snowman", "green"], ["nutcracker", "yellow"]]
	for player in 3:
		mains[player].net.send_action("pick_character", {"character": picks[player][0], "colour": picks[player][1]})
		mains[player].net.send_action("ready", {})
	assert_true(await wait_until(func(): return mains.all(func(m): return m.screen_name == "hall")), "then straight into the hall (spec 25)")


func test_main_back_to_lobby_when_host_leaves() -> void:
	var mains: Array = await make_started_mains(47552)
	var a = mains[1]
	await wait_until(func(): return a.screen_name == "hall")
	mains[0].get_parent().free()
	assert_true(await wait_until(func(): return a.screen_name == "lobby"), "Player 2 back in the lobby")
	await wait_frames(2)
	assert_contains(text_of(a, "StatusLabel"), "host left", "status")


# ---------- walking together (spec 07) ----------

func light_fuse(net: Node, fuse_index: int) -> void:
	net.send_action("try_fuse", {"wires": net.game["puzzle"]["fuses"][fuse_index]["order"].duplicate()})


func screens_are(mains: Array, wanted: String) -> Callable:
	return func(): return mains.all(func(m): return m.screen_name == wanted)


func test_everyone_walks_into_the_bathroom_and_back() -> void:
	var mains: Array = await make_started_mains(47562)
	await wait_until(screens_are(mains, "hall"))
	var a = mains[1]
	light_fuse(a.net, 1)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"][1]["solved"])
	a.net.send_action("go_to", {"place": "bathroom"})
	assert_true(await wait_until(screens_are(mains, "bathroom")), "all three in the bathroom")
	assert_eq(mains[2].screen.scene_file_path, "res://scenes/bathroom.tscn", "Gloria's bathroom screen")
	mains[2].net.send_action("go_to", {"place": "hall"})
	assert_true(await wait_until(screens_are(mains, "hall")), "all three back in the hall")


func test_everyone_walks_into_the_living_room_and_back() -> void:
	var mains: Array = await make_started_mains(47564)
	await wait_until(screens_are(mains, "hall"))
	light_fuse(mains[0].net, 0)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"][0]["solved"])
	mains[0].net.send_action("go_to", {"place": "living_room"})
	assert_true(await wait_until(screens_are(mains, "living_room")), "all three in the living room")
	assert_eq(mains[1].screen.scene_file_path, "res://scenes/living_room.tscn", "Lara's living room screen")
	await wait_frames(2)
	press(mains[1], "DoorHall")  # through the door (spec 24)
	assert_true(await wait_until(screens_are(mains, "hall")), "back in the hall")


func test_everyone_walks_into_the_bedroom_and_back() -> void:
	var mains: Array = await make_started_mains(47563)
	await wait_until(screens_are(mains, "hall"))
	light_fuse(mains[2].net, 2)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"][2]["solved"])
	mains[0].net.send_action("go_to", {"place": "bedroom"})
	assert_true(await wait_until(screens_are(mains, "bedroom")), "all three in the bedroom")
	assert_eq(mains[1].screen.scene_file_path, "res://scenes/bedroom.tscn", "Mika's bedroom screen")
	await wait_frames(2)
	press(mains[1], "DoorHall")  # through the door (spec 24)
	assert_true(await wait_until(screens_are(mains, "hall")), "back in the hall")


# ---------- the clock (spec 13) ----------

func test_every_screen_shows_the_clock() -> void:
	var solo := make_main_device("Solo4")
	var before := solo.find_child("ClockLabel", true, false)
	assert_true(before == null or not before.visible, "no clock before the game")
	var mains: Array = await make_started_mains(47573)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(61.0)
	var shows_its_time := func(m): return text_of(m, "ClockLabel") == "Midnight in " + ClockRules.as_text(ClockRules.time_left(m.net.game))
	var all_show := func(): return mains.all(func(m): return ClockRules.time_left(m.net.game) <= Settings.GAME_SECONDS - 61 and shows_its_time.call(m))
	assert_true(await wait_until(all_show), "all three show the time left")
	# 61 s after the start: one minute and a bit less than the full time (Settings.GAME_SECONDS).
	var expected := "Midnight in %s" % ClockRules.as_text(Settings.GAME_SECONDS - 61).left(4)
	assert_contains(text_of(mains[2], "ClockLabel"), expected, "about a minute less")
	var clock: Node = mains[2].find_child("ClockLabel", true, false)
	assert_true(clock != null and clock.is_visible_in_tree(), "clock visible on Player 3")


func test_last_minute_in_red() -> void:
	var mains: Array = await make_started_mains(47574)
	await wait_until(screens_are(mains, "hall"))
	var clock: Node = mains[1].find_child("ClockLabel", true, false)
	var colour: Color = clock.get_theme_color("font_color") if clock != null else Color.RED
	assert_true(colour.g > 0.6, "not red at the start: %s" % colour)
	mains[0].net.advance_clock(Settings.GAME_SECONDS - 55.0)
	await wait_until(func(): return ClockRules.time_left(mains[1].net.game) <= 55)
	colour = clock.get_theme_color("font_color") if clock != null else Color.WHITE
	assert_true(colour.r > 0.8 and colour.g < 0.4, "red in the last minute: %s" % colour)


func test_midnight_shows_the_loss_without_a_way_back() -> void:
	var mains: Array = await make_started_mains(47575)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(float(Settings.GAME_SECONDS))
	assert_true(await wait_until(screens_are(mains, "midnight")), "all three at midnight")
	await wait_frames(2)
	assert_eq(text_of(mains[1], "PlaceTitle"), "Midnight", "title")
	var title: Control = mains[1].find_child("PlaceTitle", true, false)
	if title != null:
		var middle: float = title.get_viewport().get_visible_rect().size.x / 2
		assert_true(absf(title.get_global_rect().get_center().x - middle) < 40, "title in the middle of the screen")
	assert_contains(text_of(mains[1], "Message"), "Midnight", "what happened")
	var back: Node = mains[1].find_child("BackButton", true, false)
	assert_true(back != null and not back.visible, "no way back to the hall")
	var clock: Node = mains[1].find_child("ClockLabel", true, false)
	assert_true(clock != null and not clock.visible, "clock hidden after the game")


# ---------- the inventory (spec 14) ----------

func slot_shows(main: Node, item: String) -> bool:
	var picture: Node = main.find_child("InventoryPicture_" + item, true, false)
	return picture != null and picture.visible and text_of(main, "InventoryName_" + item) != ""


func test_inventory_bar_on_every_screen_while_the_game_runs() -> void:
	var solo := make_main_device("Solo5")
	var before: Node = solo.find_child("InventoryBar", true, false)
	assert_true(before != null and not before.visible, "no bar before the game")
	var mains: Array = await make_started_mains(47576)
	await wait_until(screens_are(mains, "hall"))
	var bar: Control = mains[1].find_child("InventoryBar", true, false)
	assert_true(bar != null and bar.is_visible_in_tree(), "bar shown in the game")
	for item in ["gift_1", "gift_2", "gift_3", "photo", "key"]:
		assert_true(mains[1].find_child("InventorySlot_" + item, true, false) != null, "slot for " + item)
		assert_eq(slot_shows(mains[1], item), false, item + " not found yet")
	if bar != null:
		await wait_frames(2)
		var r := bar.get_global_rect()
		var screen: Rect2 = bar.get_viewport().get_visible_rect()
		assert_true(screen.encloses(r), "bar fully on screen: %s" % r)
		assert_true(r.position.x > screen.size.x / 2 and r.position.y > screen.size.y / 2, "bottom right: %s" % r)
		var parts: Array = [bar]
		parts.append_array(bar.find_children("*", "Control", true, false))
		for part in parts:
			if part.name == "InventorySlot_photo":
				continue  # spec 21: a click on the photo's slot opens the photo puzzle
			assert_eq(part.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s lets clicks through" % part.name)


func test_a_found_present_shows_on_all_three_screens() -> void:
	var mains: Array = await make_started_mains(47577)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.game["bathroom"]["solved"] = true  # the host's game: taps solved
	mains[2].net.send_action("take_gift", {"room": "bathroom"})
	var everyone_sees := func(): return mains.all(func(m): return slot_shows(m, "gift_2"))
	assert_true(await wait_until(everyone_sees), "Present 2 in the bar on all three")
	assert_eq(text_of(mains[1], "InventoryName_gift_2"), "Present 2", "its name")
	var picture: Node = mains[1].find_child("InventoryPicture_gift_2", true, false)
	var file: String = picture.texture.resource_path.get_file() if picture != null and picture.texture != null else ""
	assert_eq(file, "item_gift_2.png", "its picture")
	assert_eq(slot_shows(mains[1], "gift_1"), false, "Present 1 still missing")


func test_inventory_bar_hidden_after_midnight() -> void:
	var mains: Array = await make_started_mains(47578)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(float(Settings.GAME_SECONDS))
	await wait_until(screens_are(mains, "midnight"))
	var bar: Node = mains[1].find_child("InventoryBar", true, false)
	assert_true(bar != null and not bar.visible, "bar hidden after the game")


# ---------- back to the lobby (spec 17) ----------

func test_back_to_the_lobby_after_the_end_and_play_again() -> void:
	var mains: Array = await make_started_mains(47602)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(float(Settings.GAME_SECONDS))
	assert_true(await wait_until(screens_are(mains, "midnight")), "all three see the end")
	await wait_frames(2)
	var back: Node = mains[0].find_child("BackButton", true, false)
	assert_true(back != null and back.is_visible_in_tree(), "the host sees Back to the lobby")
	assert_contains(text_of(mains[0], "BackButton"), "Back to the lobby", "its text")
	var player_back: Node = mains[1].find_child("BackButton", true, false)
	assert_true(player_back == null or not player_back.is_visible_in_tree(), "Player 2 has no button")
	var wait: Node = mains[1].find_child("WaitLabel", true, false)
	assert_true(wait != null and wait.is_visible_in_tree(), "Player 2 waits")
	assert_contains(text_of(mains[1], "WaitLabel"), "Waiting for Player 1", "for whom")
	press(mains[0], "BackButton")
	assert_true(await wait_until(screens_are(mains, "lobby")), "all three back in the lobby")
	await wait_frames(2)
	press(mains[0], "StartButton")
	assert_true(await wait_until(screens_are(mains, "select")), "a new round starts with the character selection (spec 18)")
	var picks := [["santa", "red"], ["snowman", "green"], ["nutcracker", "yellow"]]
	for player in 3:
		mains[player].net.send_action("pick_character", {"character": picks[player][0], "colour": picks[player][1]})
		mains[player].net.send_action("ready", {})
	assert_true(await wait_until(screens_are(mains, "hall")), "a new round in the hall, no story again (spec 25)")
	assert_eq(ClockRules.time_left(mains[2].net.game) >= 598, true, "the clock starts again at 10:00")


func test_end_screen_alone_shows_no_back_button() -> void:
	var ending: Node = load("res://scenes/ending.tscn").instantiate()
	ending.place = "merry"
	tree.root.add_child(ending)
	var back: Node = ending.find_child("BackButton", true, false)
	assert_true(back == null or not back.visible, "no network: no button")
	var wait: Node = ending.find_child("WaitLabel", true, false)
	assert_true(wait == null or not wait.visible, "no network: no waiting")


# After the manual test (spec 17): the button is red, so it looks clickable.
func test_back_to_the_lobby_button_is_red() -> void:
	var mains: Array = await make_started_mains(47603)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(float(Settings.GAME_SECONDS))
	await wait_until(screens_are(mains, "midnight"))
	await wait_frames(2)
	var back: Button = mains[0].find_child("BackButton", true, false)
	if back != null:
		var style = back.get_theme_stylebox("normal")
		assert_true(style is StyleBoxFlat, "its own style")
		if style is StyleBoxFlat:
			var colour: Color = style.bg_color
			assert_true(colour.r > 0.6 and colour.g < 0.35 and colour.b < 0.35 and colour.a > 0.9, "red: %s" % colour)


# ---------- sound pack (spec 22) ----------

func test_menu_music_is_quieter() -> void:
	var main := make_main_device("Solo22")
	var music: AudioStreamPlayer = main.get_node_or_null("Music")
	assert_true(music != null and music.volume_db <= -8.0, "menu music turned down: %s" % (music.volume_db if music != null else "none"))


func test_house_music_plays_quietly_while_the_game_runs() -> void:
	var solo := make_main_device("Solo23")
	assert_eq(solo.get("house_music_on"), false, "no house music before the game")
	var mains: Array = await make_started_mains(47643)
	assert_true(await wait_until(screens_are(mains, "hall")), "in the hall")
	assert_true(mains.all(func(m): return m.get("house_music_on") == true), "house music on all three")
	var house: AudioStreamPlayer = mains[1].get_node_or_null("HouseMusic")
	assert_true(house != null and house.stream != null and house.stream.resource_path.ends_with("music_house.mp3"), "music_house.mp3")
	assert_true(house != null and house.stream.loop, "it loops")
	assert_true(house != null and house.volume_db <= -14.0, "quiet")
	mains[0].net.advance_clock(float(Settings.GAME_SECONDS))
	await wait_until(screens_are(mains, "midnight"))
	assert_true(mains.all(func(m): return m.get("house_music_on") == false), "stops at the end")


# ---------- the story before the hall (spec 23) ----------

# Spec 25: the story comes first on each device, before the title, on its own.
func test_the_story_at_the_start_fades_in_without_music() -> void:
	var main := make_main_device("Story25")
	await wait_frames(2)
	assert_eq(main.screen_name, "intro", "the story")
	assert_true(main.screen.get("lead_in") != null and main.screen.lead_in >= 1.5, "the story fades in first")
	assert_eq(main.get("menu_music_on"), false, "no menu music under the story")
	var clock: Node = main.find_child("ClockLabel", true, false)
	assert_true(clock != null and not clock.visible, "no clock during the story")


func test_the_game_starts_in_the_hall_at_ten_minutes() -> void:
	var host := make_main_device("StoryHost")
	var a := make_main_device("StoryA")
	var b := make_main_device("StoryB")
	host.net.host_room(47651)
	a.net.join_room("127.0.0.1", 47651)
	await wait_until(func(): return a.net.connected)
	b.net.join_room("127.0.0.1", 47651)
	await wait_until(func(): return host.net.players.size() == 3)
	var mains := [host, a, b]
	host.net.begin_selection()
	await wait_until(screens_are(mains, "select"))
	var picks := [["santa", "red"], ["snowman", "green"], ["nutcracker", "yellow"]]
	for player in 3:
		mains[player].net.send_action("pick_character", {"character": picks[player][0], "colour": picks[player][1]})
		mains[player].net.send_action("ready", {})
	assert_true(await wait_until(screens_are(mains, "hall")), "all three in the hall, no story in between")
	assert_eq(ClockRules.time_left(b.net.game) >= 598, true, "10:00 on the clock")


# Spec 23: who skips waits on a quiet screen (no voice, no line, no "Click to skip").
func test_a_skipped_story_goes_quiet_while_waiting() -> void:
	var intro: Node = load("res://scenes/intro.tscn").instantiate()
	tree.root.add_child(intro)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	tree.root.push_input(key)
	var subtitle: Node = intro.find_child("SubtitleLabel", true, false)
	var hint: Node = intro.find_child("SkipHint", true, false)
	assert_true(subtitle != null and not subtitle.visible, "the line is gone")
	assert_true(hint != null and not hint.visible, "no Click to skip any more")
	var voice: AudioStreamPlayer = intro.find_child("Voice", true, false)
	assert_true(voice != null and not voice.playing, "the voice is quiet")


# Spec 23, after the manual test: the story fades in, then the voice starts.
func test_the_story_fades_in_before_the_voice() -> void:
	var intro: Node = load("res://scenes/intro.tscn").instantiate()
	intro.lead_in = 2.0
	tree.root.add_child(intro)
	var fade: Node = intro.find_child("FadeIn", true, false)
	assert_true(fade != null and fade.color.a > 0.9, "starts dark")
	assert_eq(intro.get("voice_started"), false, "no voice yet")
	var subtitle: Node = intro.find_child("SubtitleLabel", true, false)
	assert_true(subtitle != null and subtitle.modulate.a < 0.1, "no line yet")
	intro.advance(1.0)
	assert_true(fade != null and fade.color.a > 0.3 and fade.color.a < 0.7, "half way: %s" % (fade.color.a if fade != null else -1.0))
	intro.advance(1.5)
	assert_true(fade != null and fade.color.a < 0.05, "fully faded in")
	assert_eq(intro.get("voice_started"), true, "now the voice starts")
	assert_eq(text_of(intro, "SubtitleLabel"), "Once I was Santa's most loyal helper.", "the first line")

