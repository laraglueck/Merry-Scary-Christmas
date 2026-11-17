# Tests for spec 04: the main scene switches between lobby and hall.
extends "res://tests/base_test.gd"

const MainScene = preload("res://scenes/main.tscn")


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


func test_main_starts_with_the_title() -> void:
	var main := make_main_device("Solo")
	assert_eq(main.screen_name, "title", "title first (spec 11)")
	assert_true(main.find_child("StartButton", true, false) != null, "start button shown")
	assert_true(main.find_child("CreateButton", true, false) == null, "no lobby yet")


func test_main_start_on_the_title_opens_the_lobby() -> void:
	var main := make_main_device("Solo2")
	press(main, "StartButton")
	assert_eq(main.screen_name, "lobby", "lobby after Start")
	await wait_frames(2)  # the old title is removed at the end of a frame
	assert_true(main.find_child("CreateButton", true, false) != null, "lobby shown")
	assert_true(main.find_child("TitleLabel", true, false) == null, "title gone")


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
