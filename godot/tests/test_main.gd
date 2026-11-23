# Tests for spec 04: the main scene switches between lobby and hall.
extends "res://tests/base_test.gd"

const MainScene = preload("res://scenes/main.tscn")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const Settings = preload("res://scripts/settings.gd")
const Comfort = preload("res://scripts/comfort.gd")


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
	main.screen.accepted.emit()  # the flashing warning (spec 34)
	assert_eq(main.screen_name, "intro", "the story first, before the title (spec 25)")
	await wait_frames(2)
	assert_true(main.find_child("SubtitleLabel", true, false) != null, "story shown")
	assert_true(main.find_child("StartButton", true, false) == null, "no title yet")


func test_main_story_then_title_then_lobby() -> void:
	var main := make_main_device("Solo2")
	main.screen.accepted.emit()  # the flashing warning (spec 34)
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
	assert_eq(main.get("menu_music_on"), false, "no music under the warning")
	main.screen.accepted.emit()  # the flashing warning (spec 34)
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
	# Hero powers: each player sees their own hero's power at the top and can use it once.
	await wait_frames(2)
	assert_contains(text_of(mains[0], "PowerButton"), "Ho ho hint", "Santa's power for Player 1")
	assert_contains(text_of(mains[1], "PowerButton"), "Freeze", "the snowman's for Player 2")
	press(mains[1], "PowerButton")
	assert_true(await wait_until(func(): return "Freeze" in str(mains[2].net.game.get("last_event", ""))), "everyone sees it")
	await wait_frames(2)
	assert_eq(is_disabled(mains[1], "PowerButton"), true, "only once")


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
	var name_field: LineEdit = mains[0].find_child("NameField", true, false)
	if name_field != null:
		name_field.text = "Team Rudolph"
		name_field.text_changed.emit("Team Rudolph")
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
	main.screen.accepted.emit()  # the flashing warning (spec 34)
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


# ---------- pause (spec 26) ----------

func test_anyone_pauses_for_everyone_and_anyone_continues() -> void:
	var mains: Array = await make_started_mains(47660)
	assert_true(await wait_until(screens_are(mains, "hall")), "in the hall")
	await wait_frames(2)
	var pause: Node = mains[1].find_child("PauseButton", true, false)
	assert_true(pause != null and pause.is_visible_in_tree(), "Pause button while the game runs")
	press(mains[1], "PauseButton")  # Player 2 pauses
	var all_paused := func(): return mains.all(func(m):
		var overlay: Node = m.find_child("PauseOverlay", true, false)
		return overlay != null and overlay.is_visible_in_tree())
	assert_true(await wait_until(all_paused), "all three see the pause")
	assert_contains(text_of(mains[0], "PauseLabel"), "Paused by Player 2", "says who")
	var played: int = mains[0].net.game["seconds_played"]
	mains[0].net.advance_clock(30.0)
	assert_eq(mains[0].net.game["seconds_played"], played, "the clock stands still")
	press(mains[2], "ContinueButton")  # Player 3 continues
	var all_running := func(): return mains.all(func(m):
		var overlay: Node = m.find_child("PauseOverlay", true, false)
		return overlay != null and not overlay.visible)
	assert_true(await wait_until(all_running), "the game runs again for all three")
	mains[0].net.advance_clock(2.0)
	assert_eq(mains[0].net.game["seconds_played"], played + 2, "the clock runs again")


func test_no_pause_button_before_the_game() -> void:
	var main := make_main_device("NoPause")
	var pause: Node = main.find_child("PauseButton", true, false)
	assert_true(pause == null or not pause.is_visible_in_tree(), "no Pause on the story or the title")


func test_browser_leaving_pauses_until_continue() -> void:
	var main := make_main_device("WebPause")
	assert_true(main.has_method("_set_web_page_away"), "handles browser focus changes")
	if not main.has_method("_set_web_page_away"):
		return
	main.net.play_alone()
	main.net.start_game()
	var played: int = main.net.game["seconds_played"]
	var continue_button := find(main, "ContinueButton") as Button

	main._set_web_page_away(true)
	assert_true(tree.paused and main.net.game["paused"], "the scene and the saved game pause")
	assert_true(AudioServer.is_bus_mute(0), "all browser audio is muted")
	assert_true(main.pause_overlay.visible and continue_button.disabled, "the pause is visible while away")
	assert_contains(main.pause_label.text, "Paused")
	main.net.advance_clock(4.0)
	assert_eq(main.net.game["seconds_played"], played, "the timer stays still")
	continue_button.pressed.emit()
	assert_true(tree.paused, "cannot resume while the page is away")

	main._set_web_page_away(false)
	assert_true(tree.paused and main.pause_overlay.visible, "returning keeps the pause")
	assert_true(AudioServer.is_bus_mute(0) and not continue_button.disabled, "audio waits for Continue too")
	press(main, "ContinueButton")
	assert_true(not tree.paused and not main.net.game["paused"], "Continue resumes the game")
	assert_true(not main.pause_overlay.visible and not AudioServer.is_bus_mute(0), "the overlay clears and audio resumes")
	main.net.advance_clock(2.0)
	assert_eq(main.net.game["seconds_played"], played + 2, "the timer resumes")


func test_browser_pause_preserves_disabled_music_before_play() -> void:
	var main := make_main_device("WebTitlePause")
	assert_true(main.has_method("_set_web_page_away"), "handles browser focus changes")
	if not main.has_method("_set_web_page_away"):
		return
	main.warning_done = true
	main.story_done = true
	main._update_screen()
	main.music.play()  # headless does not start the title music automatically
	main.toggle_music()
	main._set_web_page_away(true)
	assert_true(main.pause_overlay.visible and tree.paused, "the title pauses too")
	main._set_web_page_away(false)
	press(main, "ContinueButton")
	assert_true(not main.music_enabled and main.music.stream_paused, "music switched off stays off")
	main.music.stop()


# ---------- playtest fixes (spec 29) ----------

func test_pause_and_help_sit_together_next_to_the_penalty() -> void:
	tree.root.size = Vector2i(1152, 648)
	var mains: Array = await make_started_mains(47673)
	await wait_until(screens_are(mains, "hall"))
	await wait_frames(3)
	var m: Node = mains[1]
	var pause: Button = m.find_child("PauseButton", true, false)
	var help: Button = m.find_child("MissionButton", true, false)
	var penalty: Control = m.find_child("PenaltyLabel", true, false)
	assert_true(pause != null and help != null and penalty != null, "all three there")
	if pause == null or help == null or penalty == null:
		return
	var p := pause.get_global_rect()
	var h := help.get_global_rect()
	var pen := penalty.get_global_rect()
	assert_true(absf(p.get_center().y - h.get_center().y) < 4 and absf(pen.get_center().y - h.get_center().y) < 6, "one row: %s %s %s" % [pen, h, p])
	assert_true(pen.end.x <= h.position.x and h.end.x <= p.position.x, "penalty, then ?, then Pause")
	assert_true(h.position.x - pen.end.x < 30 and p.position.x - h.end.x < 20, "close together")
	assert_true(p.end.x > 1152 - 40 and p.position.y < 30, "top right")
	for button in [pause, help]:
		assert_true(button.get_global_rect().size.y >= 40, button.name + " big enough to click")
		var normal = button.get_theme_stylebox("normal")
		var hover = button.get_theme_stylebox("hover")
		assert_true(normal is StyleBoxFlat and normal.border_width_top >= 2, button.name + " has a frame")
		assert_true(hover is StyleBoxFlat and hover.bg_color != normal.bg_color, button.name + " lights up on hover")
		assert_eq(button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, button.name + " shows the hand")


func test_the_inventory_steps_aside_for_the_window() -> void:
	var mains: Array = await make_started_mains(47674)
	await wait_until(screens_are(mains, "hall"))
	light_fuse(mains[0].net, 0)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"][0]["solved"])
	mains[0].net.send_action("go_to", {"place": "living_room"})
	assert_true(await wait_until(screens_are(mains, "living_room")), "in the living room")
	await wait_frames(2)
	var bar: Control = mains[1].find_child("InventoryBar", true, false)
	assert_true(bar != null and bar.visible, "the inventory is there")
	press(mains[1], "WindowButton")
	assert_eq(bar.visible, false, "hidden while Player 2 looks out of the window")
	var played: int = mains[1].net.game.get("seconds_played", 0)
	mains[0].net.advance_clock(1.0)
	await wait_until(func(): return mains[1].net.game.get("seconds_played", 0) > played)
	assert_eq(bar.visible, false, "still hidden when the game changes")
	var other: Control = mains[2].find_child("InventoryBar", true, false)
	assert_true(other != null and other.visible, "only on that device")
	for down in [true, false]:
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = down
		tree.root.push_input(esc)
	await wait_frames(2)
	assert_eq(bar.visible, true, "back when the view closes")


# Spec 29: Pause moved to the top right; in no room may it cover a button of that room.
func test_pause_covers_no_button_in_any_room() -> void:
	tree.root.size = Vector2i(1152, 648)
	var mains: Array = await make_started_mains(47675)
	await wait_until(screens_are(mains, "hall"))
	for i in 3:
		light_fuse(mains[i].net, i)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"].all(func(f): return f["solved"]))
	for place in ["living_room", "bathroom", "bedroom", "attic"]:
		mains[0].net.send_action("go_to", {"place": "hall"})
		await wait_until(screens_are(mains, "hall"))
		mains[0].net.send_action("go_to", {"place": place})
		assert_true(await wait_until(screens_are(mains, place)), "in the " + place)
		await wait_frames(3)
		var pause: Button = mains[0].find_child("PauseButton", true, false)
		var p := pause.get_global_rect()
		for button in mains[0].screen.find_children("*", "BaseButton", true, false):
			if button.is_visible_in_tree():
				assert_true(not p.intersects(button.get_global_rect()), "%s: Pause covers %s" % [place, button.name])



# Playtest (Lara): the result of a power was covered at the bottom (and not shown in the
# bedroom). Now it shows in a box right under the power button, for everyone, in every room.
func test_a_power_shows_its_result_under_the_power_button() -> void:
	var mains: Array = await make_started_mains(47681)
	assert_true(await wait_until(func(): return mains.all(func(m): return m.screen_name == "hall")), "in the hall")
	await wait_frames(2)
	var box: Control = mains[2].find_child("PowerMessage", true, false)
	assert_true(box != null and not box.visible, "no box before a power is used")
	mains[0].net.game["characters"] = {1: {"character": "snowman", "colour": "green", "accessory": "none"}}  # the host decides
	mains[1].net.send_action("use_power", {})
	assert_true(await wait_until(func(): return mains.all(func(m): return m.find_child("PowerMessage", true, false).visible)), "everyone sees it")
	await wait_frames(2)
	for m in mains:
		assert_contains(text_of(m, "PowerMessage"), "Freeze", "what happened")
	var rect: Rect2 = box.get_global_rect()
	var button: Rect2 = mains[2].find_child("PowerButton", true, false).get_global_rect()
	assert_true(rect.position.y >= button.end.y and rect.end.y < 360, "right under the power button, far from the bottom bar")
	mains[2].close_power_message()
	assert_eq(box.visible, false, "a click closes it")


# ---------- a penalty you can see (spec 34) ----------

func test_a_wrong_fuse_floats_the_lost_seconds_and_shakes_everyone() -> void:
	var mains: Array = await make_started_mains(47692)
	assert_true(await wait_until(screens_are(mains, "hall")), "in the hall")
	await wait_frames(2)
	for m in mains:
		var float_label: Node = m.find_child("PenaltyFloat", true, false)
		assert_true(float_label == null or not float_label.visible, "nothing floats at the start")
		assert_eq(m.get("shakes"), 0, "no shake at the start")
	var wrong: Array = mains[1].net.game["puzzle"]["fuses"][1]["order"].duplicate()
	wrong.reverse()
	mains[1].net.send_action("try_fuse", {"wires": wrong})
	var all_see := func(): return mains.all(func(m):
		var f: Node = m.find_child("PenaltyFloat", true, false)
		return f != null and f.visible)
	assert_true(await wait_until(all_see), "all three see the lost seconds")
	for m in mains:
		assert_eq(text_of(m, "PenaltyFloat"), "−%d s" % Settings.FUSE_PENALTY_SECONDS, "how much")
		assert_eq(m.get("shakes"), 1, "the screen shook once")


func test_a_resumed_game_with_penalties_does_not_shake() -> void:
	var main := make_main_device("Resumed")
	main._update_penalty()  # no game yet
	main.net.game = {"phase": "hall", "penalty_seconds": 40}  # as if loaded from a save
	main._update_penalty()
	assert_eq(main.get("shakes"), 0, "an old penalty does not shake")
	var float_label: Node = main.find_child("PenaltyFloat", true, false)
	assert_true(float_label == null or not float_label.visible, "and does not float")
	main.net.game["penalty_seconds"] = 60  # a new wrong answer after the resume
	main._update_penalty()
	assert_eq(main.get("shakes"), 1, "a new one does")
	assert_eq(text_of(main, "PenaltyFloat"), "−20 s", "the 20 seconds just lost")
	main.net.game = {}


# ---------- music on/off (spec 33) ----------

func test_music_button_switches_the_music_off_and_on() -> void:
	var main := make_main_device("MusicButton")
	main.story_done = true
	main._update_screen()
	var button: Button = main.find_child("MusicButton", true, false)
	assert_true(button != null and button.is_visible_in_tree(), "the music button on the title")
	if button == null:
		return
	var icon: Node = button.find_child("MusicIcon", true, false)
	assert_true(icon != null, "a drawn note in the button")
	assert_eq(main.get("music_enabled"), true, "music on at the start")
	assert_eq(icon.get("crossed"), false, "the note is not crossed out")
	main.music.play()  # the test run starts no music by itself
	main.house_music.play()
	button.pressed.emit()
	assert_eq(main.get("music_enabled"), false, "off after a click")
	assert_true(main.get_node("Music").stream_paused and main.get_node("HouseMusic").stream_paused, "both music players paused")
	assert_eq(icon.get("crossed"), true, "the note crossed out")
	assert_true(button.modulate.v < 0.9 and button.modulate.a < 1.0, "the button greyed out")
	assert_eq(button.tooltip_text, "Music on", "says what a click does")
	button.pressed.emit()
	assert_eq(main.get("music_enabled"), true, "on again")
	assert_true(not main.get_node("Music").stream_paused and not main.get_node("HouseMusic").stream_paused, "both music players go on")
	assert_eq(icon.get("crossed"), false, "the note back")
	assert_eq(button.modulate, Color.WHITE, "not greyed any more")
	assert_eq(button.tooltip_text, "Music off", "says what a click does")
	main.music.stop()
	main.house_music.stop()


func test_music_button_in_the_hall_covers_nothing() -> void:
	tree.root.size = Vector2i(1152, 648)
	var mains: Array = await make_started_mains(47690)
	assert_true(await wait_until(screens_are(mains, "hall")), "in the hall")
	await wait_frames(3)
	var button: Button = mains[0].find_child("MusicButton", true, false)
	assert_true(button != null and button.is_visible_in_tree(), "the music button in the hall")
	if button == null:
		return
	var m := button.get_global_rect()
	assert_true(m.position.x < 40 and m.position.y < 30 and m.size.x <= 48, "small, top left: %s" % m)
	for other in mains[0].find_children("*", "Control", true, false):
		if other == button or button.is_ancestor_of(other) or not other.is_visible_in_tree():
			continue
		if other is BaseButton or other.name in ["ClockLabel", "PenaltyLabel", "InventoryBar", "HallTitle"]:
			assert_true(not m.intersects(other.get_global_rect()), "covers %s" % other.name)
	# And in every room: no button of the room under it.
	for i in 3:
		light_fuse(mains[i].net, i)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"].all(func(f): return f["solved"]))
	for place in ["living_room", "bathroom", "bedroom", "attic"]:
		mains[0].net.send_action("go_to", {"place": "hall"})
		await wait_until(screens_are(mains, "hall"))
		mains[0].net.send_action("go_to", {"place": place})
		assert_true(await wait_until(screens_are(mains, place)), "in the " + place)
		await wait_frames(3)
		for other in mains[0].screen.find_children("*", "BaseButton", true, false):
			if other.is_visible_in_tree():
				assert_true(not m.intersects(other.get_global_rect()), "%s: the music button covers %s" % [place, other.name])


func test_the_ending_music_follows_the_music_button() -> void:
	var main := make_main_device("EndingMusic")
	main.toggle_music()  # off
	var ending: Node = load("res://scenes/ending.tscn").instantiate()
	ending.place = "merry"
	main.add_child(ending)
	assert_eq(ending.music_allowed(), false, "the ending asks main: music is off")
	main.toggle_music()
	assert_eq(ending.music_allowed(), true, "and on again")
	ending.queue_free()


# ---------- flashing warning (spec 34) ----------

func test_the_flashing_warning_comes_before_the_story() -> void:
	var main := make_main_device("Warning")
	assert_eq(main.screen_name, "warning", "the warning first")
	await wait_frames(2)
	assert_contains(text_of(main, "WarningText"), "photosensitive epilepsy", "says why")
	assert_true(main.find_child("SubtitleLabel", true, false) == null, "no story yet")
	press(main, "WarningContinue")
	assert_eq(main.screen_name, "intro", "then the story")


func test_the_warning_switch_reduces_flashing() -> void:
	var main := make_main_device("WarningSwitch")
	await wait_frames(1)
	assert_eq(Comfort.reduce_flashing, false, "flashing on at the start")
	assert_contains(text_of(main, "ReduceFlashingSwitch"), "Off", "the switch says Off")
	press(main, "ReduceFlashingSwitch")
	assert_eq(Comfort.reduce_flashing, true, "reduced after a click")
	assert_contains(text_of(main, "ReduceFlashingSwitch"), "On", "the switch says On")
	press(main, "ReduceFlashingSwitch")
	assert_eq(Comfort.reduce_flashing, false, "and back")


func test_the_pause_screen_has_the_flashing_switch() -> void:
	var mains: Array = await make_started_mains(47693)
	assert_true(await wait_until(screens_are(mains, "hall")), "in the hall")
	press(mains[0], "PauseButton")
	assert_true(await wait_until(func(): return mains[0].find_child("PauseOverlay", true, false).visible), "paused")
	var switch: Button = mains[0].find_child("PauseReduceFlashing", true, false)
	assert_true(switch != null and switch.is_visible_in_tree(), "the switch on the pause screen")
	if switch == null:
		return
	switch.pressed.emit()
	assert_eq(Comfort.reduce_flashing, true, "reduced from the pause screen")
	assert_contains(switch.text, "On", "says On")


# Spec 34: something new in the inventory plays the pickup sound on every device, in every
# room; starting (or joining) a game does not.
func test_a_picked_up_item_plays_the_pickup_sound_for_everyone() -> void:
	var mains: Array = await make_started_mains(47691)
	await wait_until(screens_are(mains, "hall"))
	for main in mains:
		assert_eq(main.sounds_played.count("sfx_gift.mp3"), 0, "no sound for starting the game")
	mains[0].net.game["bathroom"]["solved"] = true  # the host's game: taps solved
	mains[1].net.send_action("take_gift", {"room": "bathroom"})
	var everyone_hears := func(): return mains.all(func(m): return m.sounds_played.count("sfx_gift.mp3") == 1)
	assert_true(await wait_until(everyone_hears), "all three hear it once: %s" % [mains.map(func(m): return m.sounds_played)])

# ---------- the last minutes (spec 35) ----------

# A game alone on this device, with `left` seconds to midnight.
func make_solo_at(device_name: String, left: int) -> Node:
	var main := make_main_device(device_name)
	main.net.game = {"phase": "hall", "seconds_played": Settings.GAME_SECONDS - left}
	main._update_dread()
	return main


func test_calm_before_the_last_five_minutes() -> void:
	var main := make_solo_at("Dread0", 400)
	assert_eq(main.dread_stage, 0, "calm")
	assert_eq(main.get_node("HouseMusic").pitch_scale, 1.0, "music normal")
	assert_eq(main.dread_sounds, [], "no snore, no chime")
	var flicker: Control = main.find_child("DreadFlicker", true, false)
	assert_true(flicker != null and not flicker.visible, "no flicker")


func test_five_minutes_left_snoring_faster_music_and_a_chime() -> void:
	var main := make_solo_at("Dread1", 301)
	main.net.game["seconds_played"] += 1  # 5:00 left
	main._update_dread()
	assert_eq(main.dread_stage, 1, "stage 1")
	assert_true(is_equal_approx(main.get_node("HouseMusic").pitch_scale, Settings.DREAD_MUSIC_PITCH), "music a bit faster")
	assert_true("sfx_snore.mp3" in main.dread_sounds, "Jingles snores in every room")
	assert_eq(main.dread_sounds.count("sfx_clock_chime.mp3"), 1, "the clock strikes")
	var snore: AudioStreamPlayer = main.get_node_or_null("DreadSnore")
	assert_true(snore != null and snore.volume_db <= -18.0, "quietly")
	main.net.game["seconds_played"] += 1
	main._update_dread()
	assert_eq(main.dread_sounds.count("sfx_clock_chime.mp3"), 1, "only once for 5:00")
	assert_true(not main.find_child("DreadFlicker", true, false).visible, "no flicker yet")


func test_two_minutes_left_flicker_everywhere_and_jingles_twitches_once() -> void:
	var main := make_solo_at("Dread2", 121)
	main.net.game["seconds_played"] += 1
	main._update_dread()
	assert_eq(main.dread_stage, 2, "stage 2")
	assert_true(is_equal_approx(main.get_node("HouseMusic").pitch_scale, Settings.PANIC_MUSIC_PITCH), "faster still")
	var flicker: ColorRect = main.find_child("DreadFlicker", true, false)
	assert_true(flicker != null and flicker.visible, "the lights flicker")
	assert_eq(flicker.mouse_filter, Control.MOUSE_FILTER_IGNORE, "clicks go through")
	var shot: Control = main.find_child("JinglesTwitch", true, false)
	assert_true(shot != null and shot.visible, "Jingles twitches")
	assert_eq(main.jingles_shots, 1, "once")
	main.net.game["seconds_played"] += 5
	main._update_dread()
	assert_eq(main.jingles_shots, 1, "still once")


func test_nothing_while_paused_and_calm_again_after_the_game() -> void:
	var main := make_solo_at("Dread3", 100)
	assert_eq(main.dread_stage, 2, "panic")
	main.net.game["paused"] = true
	main._update_dread()
	assert_eq(main.dread_stage, 0, "paused: calm")
	assert_true(not main.find_child("DreadFlicker", true, false).visible, "no flicker in the pause")
	main.net.game["paused"] = false
	main.net.game["phase"] = "scary"
	main._update_dread()
	assert_eq(main.dread_stage, 0, "the game is over")
	assert_eq(main.get_node("HouseMusic").pitch_scale, 1.0, "music back to normal")


func test_with_reduced_flashing_the_last_minutes_do_not_flicker() -> void:
	Comfort.reduce_flashing = true
	var main := make_solo_at("Dread4", 100)
	var flicker: ColorRect = main.find_child("DreadFlicker", true, false)
	await tree.create_timer(0.3).timeout
	var seen := []
	for i in 6:
		seen.append(flicker.color.a)
		await tree.create_timer(0.1).timeout
	Comfort.reduce_flashing = false
	assert_true(seen.all(func(a): return is_equal_approx(a, seen[0])), "steady, no flicker: %s" % [seen])
	assert_true(seen[0] > 0.0, "but a little dark")
	main.net.game = {}
