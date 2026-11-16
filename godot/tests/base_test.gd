# Base class for our tests: every test file extends this and can use these checks.
extends RefCounted

var failures: Array[String] = []
var tree: SceneTree  # set by run_tests.gd, needed to open scenes

const NetworkScript = preload("res://scripts/net/network.gd")


func assert_eq(actual, expected, what := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s\n        expected: %s\n        actual:   %s" % [what, expected, actual])


func assert_true(condition: bool, what := "") -> void:
	if not condition:
		failures.append("%s: expected true" % what)


func assert_contains(text: String, part: String, what := "") -> void:
	if part.to_lower() not in text.to_lower():
		failures.append("%s: expected \"%s\" in \"%s\"" % [what, part, text])


# ---------- helpers for screens: find nodes, press buttons ----------

func find(screen: Node, node_name: String) -> Node:
	var node := screen.find_child(node_name, true, false)
	if node == null:
		failures.append("node not found: " + node_name)
	return node


func press(screen: Node, node_name: String) -> void:
	var button := find(screen, node_name)
	if button != null:
		button.pressed.emit()


func text_of(screen: Node, node_name: String) -> String:
	var node := find(screen, node_name)
	return node.text if node != null else ""


func is_disabled(screen: Node, node_name: String) -> bool:
	var button := find(screen, node_name)
	return button != null and button.disabled


# ---------- helpers for network tests ----------

# Every "device" gets its own branch in the scene tree with its own multiplayer,
# so host and players can talk to each other over 127.0.0.1 in one test run.
func make_device(device_name: String) -> Node:
	var device := Node.new()
	device.name = device_name
	tree.root.add_child(device)
	tree.set_multiplayer(SceneMultiplayer.new(), device.get_path())
	var net := NetworkScript.new()
	net.name = "Network"
	device.add_child(net)
	return net


# Waits frame by frame until check() is true, at most 3 seconds.
func wait_until(check: Callable) -> bool:
	var start := Time.get_ticks_msec()
	while not check.call():
		if Time.get_ticks_msec() - start > 3000:
			return false
		await tree.process_frame
	return true


func wait_frames(count: int) -> void:
	for i in count:
		await tree.process_frame


# Host + two players, all connected by address. Returns [host, player 2, player 3].
func make_full_room(port: int) -> Array:
	var host := make_device("Host")
	host.host_room(port)
	var a := make_device("A")
	a.join_room("127.0.0.1", port)
	await wait_until(func(): return a.connected)
	var b := make_device("B")
	b.join_room("127.0.0.1", port)
	await wait_until(func(): return b.connected)
	await wait_until(func(): return host.players.size() == 3)
	return [host, a, b]


# Like make_full_room, and the host has started the game.
func make_started_room(port: int) -> Array:
	var room: Array = await make_full_room(port)
	room[0].start_game()
	await wait_until(func(): return not room[1].game.is_empty() and not room[2].game.is_empty())
	return room
