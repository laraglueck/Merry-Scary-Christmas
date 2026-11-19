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


func test_all_five_spots_are_there() -> void:
	var bathroom := open_bathroom()
	for spot in ["door_hall", "mirror", "hot_tap", "cold_tap", "bathtub"]:
		find(bathroom, "Spot_" + spot)


# ---------- keys ----------

func test_arrows_move_the_highlight_from_spot_to_spot() -> void:
	var bathroom := open_bathroom()
	assert_eq(bathroom.highlighted_spot(), "door_hall", "start at the door")
	key(bathroom, "ui_left")
	assert_eq(bathroom.highlighted_spot(), "mirror", "one left")
	for i in 5:
		key(bathroom, "ui_left")
	assert_eq(bathroom.highlighted_spot(), "bathtub", "stops at the first spot")
	key(bathroom, "ui_right")
	assert_eq(bathroom.highlighted_spot(), "cold_tap", "one right")


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
	assert_eq(text_of(bathroom, "TurnsLabel"), "hot  cold", "marks")


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
	assert_contains(text_of(bathroom, "MirrorDust"), "steam", "a hint that the mirror will matter later")


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
	assert_eq(text_of(bathroom, "TurnsLabel"), "cold  hot", "teammates' turns shown")


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
	assert_eq(bathroom.sounds_played.size(), 4, "a sound for each of the four turns")
	assert_eq(bathroom.sounds_played[3], "sfx_faucet.mp3 (drain)", "the last one gurgles")
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
	assert_eq(text_of(bathroom, "Spot_hot_tap"), "Hot", "hot tap")
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
