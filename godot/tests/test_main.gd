# Tests for spec 04: the main scene switches between lobby and hall.
extends "res://tests/base_test.gd"

const MainScene = preload("res://scenes/main.tscn")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")


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


func test_main_starts_with_the_loading_screen() -> void:
	var main := make_main_device("Solo")
	assert_eq(main.screen_name, "intro", "loading screen first (spec 12)")
	assert_true(main.find_child("SubtitleLabel", true, false) != null, "story shown")


func test_main_loading_screen_then_title_then_lobby() -> void:
	var main := make_main_device("Solo2")
	main.screen.finished.emit()
	assert_eq(main.screen_name, "title", "title after the story")
	press(main, "StartButton")
	assert_eq(main.screen_name, "lobby", "lobby after Start")
	await wait_frames(2)  # the old screens are removed at the end of a frame
	assert_true(main.find_child("CreateButton", true, false) != null, "lobby shown")
	assert_true(main.find_child("TitleLabel", true, false) == null, "title gone")
	assert_true(main.find_child("SubtitleLabel", true, false) == null, "story gone")


func test_main_music_loops_through_the_screens() -> void:
	var main := make_main_device("Solo3")
	var music: AudioStreamPlayer = main.get_node_or_null("Music")
	assert_true(music != null and music.stream != null, "music in main")
	assert_true(music != null and music.stream.loop, "music loops")
	main.screen.finished.emit()
	await wait_frames(2)
	assert_true(main.get_node_or_null("Music") == music, "same music on the title")


func test_main_switches_everyone_to_the_hall_when_the_game_starts() -> void:
	var mains: Array = await make_started_mains(47551)
	var all_in_hall := func(): return mains.all(func(m): return m.screen_name == "hall")
	assert_true(await wait_until(all_in_hall), "all three show the hall")
	await wait_frames(2)  # the old lobby is removed at the end of a frame
	assert_true(mains[1].find_child("CreateButton", true, false) == null, "lobby gone on Player 2")
	assert_contains(text_of(mains[1], "FuseTitle"), "GREEN", "Player 2 plays the green fuse")


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


func test_unbuilt_room_shows_a_placeholder_with_a_way_back() -> void:
	var mains: Array = await make_started_mains(47563)
	await wait_until(screens_are(mains, "hall"))
	light_fuse(mains[0].net, 0)
	await wait_until(func(): return mains[0].net.game["puzzle"]["fuses"][0]["solved"])
	mains[0].net.send_action("go_to", {"place": "living_room"})
	assert_true(await wait_until(screens_are(mains, "living_room")), "all three in the living room")
	await wait_frames(2)
	assert_contains(text_of(mains[1], "PlaceTitle"), "living/dining room", "placeholder title")
	press(mains[1], "BackButton")
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
	var all_show := func(): return mains.all(func(m): return ClockRules.time_left(m.net.game) <= 539 and shows_its_time.call(m))
	assert_true(await wait_until(all_show), "all three show the time left")
	assert_contains(text_of(mains[2], "ClockLabel"), "Midnight in 08:5", "about 8:59 left")
	var clock: Node = mains[2].find_child("ClockLabel", true, false)
	assert_true(clock != null and clock.is_visible_in_tree(), "clock visible on Player 3")


func test_last_minute_in_red() -> void:
	var mains: Array = await make_started_mains(47574)
	await wait_until(screens_are(mains, "hall"))
	var clock: Node = mains[1].find_child("ClockLabel", true, false)
	var colour: Color = clock.get_theme_color("font_color") if clock != null else Color.RED
	assert_true(colour.g > 0.6, "not red with 10 minutes left: %s" % colour)
	mains[0].net.advance_clock(545.0)
	await wait_until(func(): return ClockRules.time_left(mains[1].net.game) <= 55)
	colour = clock.get_theme_color("font_color") if clock != null else Color.WHITE
	assert_true(colour.r > 0.8 and colour.g < 0.4, "red in the last minute: %s" % colour)


func test_midnight_shows_the_loss_without_a_way_back() -> void:
	var mains: Array = await make_started_mains(47575)
	await wait_until(screens_are(mains, "hall"))
	mains[0].net.advance_clock(600.0)
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
