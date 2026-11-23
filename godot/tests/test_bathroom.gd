# Tests for spec 10: the bathroom screen. They press keys and click spots like a player.
extends "res://tests/base_test.gd"

const BathroomScene = preload("res://scenes/bathroom.tscn")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")


# Stands in for network.gd in the online test: records what the screen sends.
class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {}
	var my_index := 1
	var sent: Array = []

	func send_action(action: String, data: Dictionary) -> void:
		sent.append([action, data])


# Opens the bathroom like starting the scene (this runs _ready).
func open_bathroom(green_fuse_on := true) -> Node:
	var bathroom = BathroomScene.instantiate()
	bathroom.seed_value = 42
	bathroom.green_fuse_on = green_fuse_on
	tree.root.add_child(bathroom)
	return bathroom


func key(bathroom: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	bathroom._unhandled_input(event)


func right_taps(bathroom: Node) -> Array:
	return bathroom.game["bathroom"]["tap_order"].duplicate()


func wrong_taps(bathroom: Node) -> Array:
	var taps := right_taps(bathroom)
	taps[0] = "cold" if taps[0] == "hot" else "hot"
	return taps


func click_taps(bathroom: Node, taps: Array) -> void:
	for tap in taps:
		press(bathroom, "Spot_%s_tap" % tap)


func background_file(bathroom: Node) -> String:
	var background: TextureRect = find(bathroom, "Background")
	if background == null or background.texture == null:
		return ""
	return background.texture.resource_path.get_file()


func is_shown(bathroom: Node, node_name: String) -> bool:
	var node := find(bathroom, node_name)
	return node != null and node.is_visible_in_tree()


# ---------- picture ----------

func test_lit_picture_when_the_green_fuse_is_on() -> void:
	assert_eq(background_file(open_bathroom()), "room_bathroom_lit.webp", "background")


func test_dark_picture_while_the_green_fuse_is_off() -> void:
	assert_eq(background_file(open_bathroom(false)), "room_bathroom_dark.webp", "background")


func test_all_six_spots_are_there() -> void:
	var bathroom := open_bathroom()
	for spot in ["door_hall", "mirror", "hot_tap", "cold_tap", "bathtub", "window"]:
		find(bathroom, "Spot_" + spot)


# ---------- keys ----------

func test_arrows_move_the_highlight_from_spot_to_spot() -> void:
	var bathroom := open_bathroom()
	assert_eq(bathroom.highlighted_spot(), "door_hall", "start at the door")
	key(bathroom, "ui_left")
	assert_eq(bathroom.highlighted_spot(), "mirror", "one left")
	for i in 6:
		key(bathroom, "ui_left")
	assert_eq(bathroom.highlighted_spot(), "window", "stops at the first spot")
	key(bathroom, "ui_right")
	assert_eq(bathroom.highlighted_spot(), "bathtub", "one right")


func test_bathroom_window_uses_the_shared_nuuk_view() -> void:
	tree.root.size = Vector2i(1152, 648)
	var bathroom := open_bathroom()
	await wait_frames(2)
	var hotspot := find(bathroom, "Spot_window") as Button
	if hotspot == null:
		return
	assert_true(Rect2(60, 60, 105, 210).encloses(hotspot.get_global_rect()), "aligned with the window above the bathtub")
	assert_true(hotspot.get_global_rect().has_point(Vector2(95, 166)), "covers the glass")
	var hover := hotspot.get_theme_stylebox("hover") as StyleBoxFlat
	assert_true(hover != null and hover.border_color.is_equal_approx(Color("ffd76a")) and not hover.draw_center, "gold outline without a fill")

	var before: Dictionary = bathroom.game.duplicate(true)
	for i in 5:
		key(bathroom, "ui_left")
	key(bathroom, "ui_accept")
	var view := find(bathroom, "WindowView") as Control
	if view == null:
		return
	bathroom.size = Vector2(864, 486)
	await wait_frames(2)
	var stage := find(bathroom, "Stage") as Control
	assert_eq(stage.scale, Vector2(0.75, 0.75), "the room shrinks")
	assert_true(view.get_global_rect().is_equal_approx(stage.get_global_rect()), "the window covers the resized stage")
	assert_true(view.is_in_group("hides_inventory"), "the HUD steps aside")
	view.show_weather({"kind": "rain", "text": "Nuuk, Greenland"})
	view.finish_wipe()
	assert_contains(text_of(view, "WeatherLine"), "Nuuk")
	var audio := find(view, "WeatherAudio") as AudioStreamPlayer
	assert_true(audio != null and audio.stream != null, "uses the shared weather audio")

	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	tree.root.push_input(escape)
	assert_true(not view.visible and not view.is_in_group("hides_inventory"), "Esc closes the view")
	await wait_frames(2)

	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = hotspot.get_global_rect().get_center()
		click.global_position = click.position
		tree.root.push_input(click)
	var reopened := find(bathroom, "WindowView") as Control
	if reopened == null:
		return
	var enter := InputEventAction.new()
	enter.action = "ui_accept"
	enter.pressed = true
	tree.root.push_input(enter)
	assert_true(not reopened.visible, "Enter closes the view after a mouse click")
	assert_eq(bathroom.game, before, "no shared game changes")


func test_enter_uses_the_highlighted_spot() -> void:
	var bathroom := open_bathroom()
	key(bathroom, "ui_left")
	key(bathroom, "ui_left")  # hot tap
	key(bathroom, "ui_accept")
	assert_eq(bathroom.game["bathroom"]["turns"], ["hot"], "one hot turn")


func test_keyboard_only_solves_the_taps() -> void:
	var bathroom := open_bathroom()
	key(bathroom, "ui_left")
	key(bathroom, "ui_left")  # hot tap
	for tap in right_taps(bathroom):
		var spot := "%s_tap" % tap
		while bathroom.highlighted_spot() != spot:
			key(bathroom, "ui_left" if spot == "cold_tap" else "ui_right")
		key(bathroom, "ui_accept")
	assert_eq(bathroom.game["bathroom"]["solved"], true, "solved with keys only")


# ---------- taps ----------

func test_each_turn_shows_a_mark() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_hot_tap")
	press(bathroom, "Spot_cold_tap")
	assert_eq(text_of(bathroom, "TurnsLabel"), "warm  cold", "marks, in the rhyme's words")


func test_four_right_turns_solve_the_bathroom() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(bathroom.game["bathroom"]["solved"], true, "solved")
	assert_contains(text_of(bathroom, "Message"), "drains away", "message")
	assert_eq(text_of(bathroom, "TurnsLabel"), "", "marks cleared")


func test_wrong_order_clears_the_marks_and_costs_20_seconds() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, wrong_taps(bathroom))
	assert_eq(bathroom.game["bathroom"]["solved"], false, "not solved")
	assert_eq(bathroom.game["penalty_seconds"], 20, "penalty")
	assert_contains(text_of(bathroom, "Message"), "-20 s", "message")
	assert_eq(text_of(bathroom, "TurnsLabel"), "", "marks cleared")


func test_moving_the_highlight_keeps_the_teams_turns() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_hot_tap")
	press(bathroom, "Spot_mirror")
	assert_eq(bathroom.game["bathroom"]["turns"], ["hot"], "turn kept for the team")


func test_taps_are_dry_after_solving() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	press(bathroom, "Spot_hot_tap")
	assert_eq(bathroom.game["bathroom"]["turns"], [], "no new turn")
	assert_contains(text_of(bathroom, "Message"), "dry", "message")


# ---------- mirror ----------

func test_mirror_shows_only_dust_before_solving() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_mirror")
	assert_eq(is_shown(bathroom, "MirrorPanel"), true, "close-up open")
	assert_eq(is_shown(bathroom, "MirrorSymbols"), false, "no symbols")
	assert_contains(text_of(bathroom, "Message"), "dust", "message")
	assert_contains(text_of(bathroom, "MirrorDust"), "taps in the right order", "a hint that the mirror will matter later")


func test_mirror_shows_the_symbols_reversed_and_flipped_after_solving() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	press(bathroom, "Spot_mirror")
	assert_eq(is_shown(bathroom, "MirrorSymbols"), true, "symbols shown")
	var names := []
	for i in 3:
		var symbol: TextureRect = find(bathroom, "MirrorSymbol%d" % i)
		if symbol != null:
			names.append(symbol.texture.resource_path.get_file())
			assert_eq(symbol.flip_h, true, "symbol %d flipped" % i)
	# The chest's symbols (or, before the bedroom exists, the example bell, star, tree),
	# shown in reverse order: bell, star, tree -> tree, star, bell.
	var wheels: Array = bathroom.game.get("bedroom", {}).get("wheels", ["bell", "star", "tree"])
	var expected := []
	for i in range(2, -1, -1):
		expected.append("sym_%s.png" % wheels[i])
	assert_eq(names, expected, "reversed")


func test_escape_closes_the_mirror() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_mirror")
	key(bathroom, "ui_cancel")
	assert_eq(is_shown(bathroom, "MirrorPanel"), false, "closed")


# ---------- bathtub and present ----------

func test_present_and_digit_appear_only_after_solving() -> void:
	var bathroom := open_bathroom()
	assert_eq(is_shown(bathroom, "Gift"), false, "no present before")
	assert_eq(background_file(bathroom), "room_bathroom_lit.webp", "full tub before")
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(is_shown(bathroom, "Gift"), true, "present after")
	assert_eq(background_file(bathroom), "room_bathroom_drained.webp", "tub drained after")
	assert_eq(text_of(bathroom, "DigitLabel"), str(bathroom.game["bathroom"]["digit"]), "digit")


func test_present_is_refused_before_solving() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_bathtub")
	assert_eq(bathroom.game["bathroom"]["gift_taken"], false, "not taken")
	assert_contains(text_of(bathroom, "Message"), "not solved", "message")


func test_present_can_be_taken_once() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	press(bathroom, "Spot_bathtub")
	assert_eq(bathroom.game["bathroom"]["gift_taken"], true, "taken")
	assert_eq(is_shown(bathroom, "Gift"), false, "gone from the tub")
	assert_contains(text_of(bathroom, "Message"), "second present", "message")
	press(bathroom, "Spot_bathtub")
	assert_contains(text_of(bathroom, "Message"), "already taken", "second time")


# ---------- online ----------

func test_online_marks_show_the_turns_of_the_whole_team() -> void:
	var offline := open_bathroom()
	var net := FakeNet.new()
	net.game = offline.game.duplicate(true)
	net.game["bathroom"]["turns"] = ["cold", "hot"]  # turned by teammates
	tree.root.add_child(net)
	var bathroom = BathroomScene.instantiate()
	bathroom.net = net
	tree.root.add_child(bathroom)
	assert_eq(text_of(bathroom, "TurnsLabel"), "cold  warm", "teammates' turns shown")


func test_online_turns_and_present_go_to_the_host() -> void:
	var offline := open_bathroom()
	var net := FakeNet.new()
	net.game = offline.game.duplicate(true)
	tree.root.add_child(net)
	var bathroom = BathroomScene.instantiate()
	bathroom.net = net
	tree.root.add_child(bathroom)
	click_taps(bathroom, ["hot", "hot", "cold", "cold"])
	press(bathroom, "Spot_bathtub")
	assert_eq(net.sent, [
		["turn_tap", {"tap": "hot"}],
		["turn_tap", {"tap": "hot"}],
		["turn_tap", {"tap": "cold"}],
		["turn_tap", {"tap": "cold"}],
		["take_gift", {"room": "bathroom"}],
	], "sent to the host")
	assert_eq(net.game["bathroom"]["solved"], false, "only the host changes the game")


# ---------- effects (spec 20) ----------

func test_a_turn_plays_the_tap() -> void:
	var bathroom := open_bathroom()
	press(bathroom, "Spot_hot_tap")
	assert_eq(bathroom.sounds_played, ["sfx_faucet.mp3"], "tap sound")


func test_solving_gurgles_and_the_steam_rises() -> void:
	var bathroom := open_bathroom()
	assert_eq(is_shown(bathroom, "Steam"), false, "no steam before")
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(bathroom.sounds_played.size(), 5, "a sound for each of the first three turns, then drain and steam")
	assert_eq(bathroom.sounds_played[3], "sfx_drain.mp3", "the tub drains")
	assert_eq(bathroom.sounds_played[4], "sfx_steam.mp3", "the steam hisses")
	assert_eq(is_shown(bathroom, "Steam"), true, "steam over the mirror")
	press(bathroom, "Spot_mirror")
	assert_eq(is_shown(bathroom, "MirrorSteam"), true, "steam behind the symbols")


func test_the_face_shows_the_first_time_only() -> void:
	var bathroom := open_bathroom()
	bathroom.forget_face()
	press(bathroom, "Spot_mirror")
	assert_eq(is_shown(bathroom, "MirrorFace"), true, "face in the glass")
	assert_true("sfx_scare.mp3" in bathroom.sounds_played, "scare sound")
	assert_eq(bathroom.game["penalty_seconds"], 0, "costs no time")
	key(bathroom, "ui_cancel")
	var again := open_bathroom()  # a later visit to the bathroom
	press(again, "Spot_mirror")
	assert_eq(is_shown(again, "MirrorFace"), false, "not a second time")
	assert_true(not "sfx_scare.mp3" in again.sounds_played, "no second scare")


func test_online_a_teammates_turn_plays_the_tap() -> void:
	var offline := open_bathroom()
	var net := FakeNet.new()
	net.game = offline.game.duplicate(true)
	tree.root.add_child(net)
	var bathroom = BathroomScene.instantiate()
	bathroom.net = net
	tree.root.add_child(bathroom)
	net.game["bathroom"]["turns"] = ["cold"]  # a teammate turned the cold tap
	net.game_changed.emit()
	assert_eq(bathroom.sounds_played, ["sfx_faucet.mp3"], "heard here too")


func test_the_present_itself_can_be_clicked() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	press(bathroom, "Gift")  # players click the present, not the tub around it
	assert_eq(bathroom.game["bathroom"]["gift_taken"], true, "taken")
	assert_true(InventoryRules.has(bathroom.game, "gift_2"), "in the inventory")


func test_the_present_catches_mouse_clicks() -> void:
	var bathroom := open_bathroom()
	var gift: Control = find(bathroom, "Gift")
	assert_true(gift.mouse_filter != Control.MOUSE_FILTER_IGNORE, "a real click lands on the present")


# ---------- the torn photo (spec 21) ----------

func test_a_torn_piece_lies_in_the_drained_tub() -> void:
	var bathroom := open_bathroom()
	assert_eq(is_shown(bathroom, "PhotoPiece"), false, "not before the tub drains")
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(is_shown(bathroom, "PhotoPiece"), true, "in the tub")
	press(bathroom, "PhotoPiece")
	assert_true(InventoryRules.has(bathroom.game, "photo_piece_2"), "in the inventory")
	assert_eq(is_shown(bathroom, "PhotoPiece"), false, "gone from the tub")
	assert_contains(text_of(bathroom, "Message"), "torn piece", "message")


# ---------- tidier rooms (spec 21) ----------

func test_only_the_taps_have_names() -> void:
	var bathroom := open_bathroom()
	assert_eq(text_of(bathroom, "Spot_hot_tap"), "Warm", "warm tap, like in the rhyme")
	assert_eq(text_of(bathroom, "Spot_cold_tap"), "Cold", "cold tap")
	for spot in ["door_hall", "mirror", "bathtub"]:
		assert_eq(text_of(bathroom, "Spot_" + spot), "", "no name on " + spot)


func test_the_room_scales_as_a_whole_when_the_window_changes() -> void:
	var bathroom := open_bathroom()
	bathroom.size = Vector2(576, 600)  # a narrow window
	var stage: Control = find(bathroom, "Stage")
	assert_eq(stage.scale, Vector2(0.5, 0.5), "half as large")
	assert_eq(stage.position, Vector2(0, 138), "centred, with bars above and below")
	bathroom.size = Vector2(1152, 648)
	assert_eq(stage.scale, Vector2(1, 1), "full size again")


# ---------- second test round (fix/room-feedback) ----------

func test_the_bathtub_area_goes_once_the_tub_is_drained() -> void:
	var bathroom := open_bathroom()
	assert_eq(is_shown(bathroom, "Spot_bathtub"), true, "before: the full tub")
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(is_shown(bathroom, "Spot_bathtub"), false, "after: present and piece are clicked themselves")


func test_no_frame_until_the_arrow_keys_are_used() -> void:
	var bathroom := open_bathroom()
	var door: Button = find(bathroom, "Spot_door_hall")
	assert_eq(door.get_theme_stylebox("normal").border_color.a, 0.0, "no frame at first")
	key(bathroom, "ui_left")
	var mirror: Button = find(bathroom, "Spot_mirror")
	assert_eq(mirror.get_theme_stylebox("normal").border_color, bathroom.HIGHLIGHT, "the key frame shows")


func test_the_symbols_appear_in_the_steamed_mirror_by_themselves() -> void:
	var bathroom := open_bathroom()
	assert_eq(is_shown(bathroom, "RoomMirrorSymbols"), false, "not before")
	click_taps(bathroom, right_taps(bathroom))
	assert_eq(is_shown(bathroom, "RoomMirrorSymbols"), true, "in the mirror, without clicking it")
	var wheels: Array = bathroom.game.get("bedroom", {}).get("wheels", ["bell", "star", "tree"])
	var first: TextureRect = find(bathroom, "RoomMirrorSymbol0")
	assert_eq(first.texture.resource_path.get_file(), "sym_%s.png" % wheels[2], "reversed, like in a mirror")
	assert_eq(first.flip_h, true, "and flipped")


func test_the_face_in_the_mirror_stays_longer() -> void:
	var bathroom := open_bathroom()
	assert_true(bathroom.FACE_SECONDS >= 1.5, "long enough to be scary")


func test_the_turns_do_not_say_how_many_are_needed() -> void:
	var bathroom := open_bathroom()
	assert_eq(text_of(bathroom, "TurnsLabel"), "", "nothing before the first turn")
	press(bathroom, "Spot_hot_tap")
	assert_true(not text_of(bathroom, "TurnsLabel").contains("4"), "how many stays a secret")
	assert_contains(text_of(bathroom, "Message"), "warm tap", "the message says warm too")


# Playtest (Lara): a long message ran under the inventory bar at the bottom right.
# The message line now ends before the bar and wraps onto a second line instead.
func check_message_clear_of_the_inventory_bar(screen: Node) -> void:
	var message: Label = screen.find_child("Message", true, false)
	assert_true(message.position.x + message.size.x <= 690, "ends before the inventory bar (x %d)" % (message.position.x + message.size.x))
	assert_true(message.autowrap_mode != TextServer.AUTOWRAP_OFF, "a long message wraps")
	assert_true(message.position.y + message.size.y <= 640, "still on the screen")


func test_the_message_is_not_covered_by_the_inventory_bar() -> void:
	check_message_clear_of_the_inventory_bar(open_bathroom())


# Spec 34: "the pipes rattle angrily" has a sound of its own.
func test_a_wrong_order_rattles_the_pipes() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, wrong_taps(bathroom))
	assert_eq(bathroom.game["penalty_seconds"] > 0, true, "a wrong order")
	assert_true("sfx_key_lock.mp3" in bathroom.sounds_played, "the pipes rattle: %s" % [bathroom.sounds_played])


func test_the_right_order_does_not_rattle() -> void:
	var bathroom := open_bathroom()
	click_taps(bathroom, right_taps(bathroom))
	assert_true(not "sfx_key_lock.mp3" in bathroom.sounds_played, "no rattle")
