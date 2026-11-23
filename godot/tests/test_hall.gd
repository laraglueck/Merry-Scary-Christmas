# Tests for spec 02: the hall scene. They click buttons like a player would.
# Seed 42 gives: legend star = white, bell = blue, tree = black, snowflake = yellow
#   red fuse   (Player 1): white, blue, yellow, black  label: star, bell, snowflake, tree
#   green fuse (Player 2): blue, black, yellow, white  label: bell, tree, snowflake, star
#   gold fuse  (Player 3): blue, yellow, white, black  label: bell, snowflake, star, tree
extends "res://tests/base_test.gd"

const HallScene = preload("res://scenes/hall.tscn")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const HallScript = preload("res://scripts/hall.gd")
const Settings = preload("res://scripts/settings.gd")
const Comfort = preload("res://scripts/comfort.gd")

const RED_RIGHT := ["white", "blue", "yellow", "black"]
const GREEN_RIGHT := ["blue", "black", "yellow", "white"]
const GOLD_RIGHT := ["blue", "yellow", "white", "black"]
const RED_WRONG := ["blue", "white", "yellow", "black"]


# Opens the hall like starting the scene (this runs _ready).
func open_hall() -> Node:
	tree.root.size = Vector2i(1152, 648)
	var hall = HallScene.instantiate()
	hall.seed_value = 42
	tree.root.add_child(hall)
	return hall


# The torn label's symbols, read from its four pictures.
func label_pictures(hall: Node) -> Array:
	var symbols := []
	for i in 4:
		symbols.append(texture_file(hall, "LabelSymbol%d" % i).trim_prefix("sym_").trim_suffix(".png"))
	return symbols


# Change after manual test 3: the pictures speak for themselves, no list of names.
func assert_no_symbol_names(text: String) -> void:
	for symbol in Settings.SYMBOLS:
		assert_true(not text.contains(symbol), "no symbol names in the text: %s" % text)


# The colour of the frame around the order's symbols: whose fuse the order is for.
func frame_colour(hall: Node) -> Color:
	var frame: Node = hall.find_child("LabelFrame", true, false)
	return frame.get_theme_stylebox("panel").border_color if frame != null else Color.TRANSPARENT


func click_wires(hall: Node, colours: Array) -> void:
	for colour in colours:
		press(hall, "Wire_" + colour)


# ---------- house plan ----------

func test_house_plan_shows_legend() -> void:
	var hall := open_hall()
	for pair in [["star", "white"], ["bell", "blue"], ["tree", "black"], ["snowflake", "yellow"]]:
		assert_eq(text_of(hall, "LegendEntry_" + pair[0]), "%s = %s" % pair, "legend " + pair[0])
		assert_eq(texture_file(hall, "LegendSymbol_" + pair[0]), "sym_%s.png" % pair[0], "symbol picture " + pair[0])


func test_all_rooms_dark_at_start() -> void:
	var hall := open_hall()
	for i in 3:
		assert_contains(text_of(hall, "RoomLamp%d" % i), "dark", "lamp %d" % i)
	assert_eq(text_of(hall, "PenaltyLabel"), "Penalty: 0 s", "penalty")


# ---------- fuse panel ----------

func test_fuse_box_opens_fuse_panel() -> void:
	var hall := open_hall()
	var panel := find(hall, "FusePanel")
	assert_eq(panel != null and panel.visible, false, "panel hidden at start")
	press(hall, "FuseBoxButton")
	assert_eq(panel != null and panel.visible, true, "panel visible after click")


func test_player_1_has_red_fuse_and_sees_gold_label() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	assert_contains(text_of(hall, "FuseTitle"), "red", "own fuse")
	var hint := text_of(hall, "LabelHint")
	assert_eq(frame_colour(hall), HallScript.UI_COLOURS["gold"], "the order of which fuse (its frame)")
	assert_eq(label_pictures(hall), ["bell", "snowflake", "star", "tree"], "label symbols as pictures")
	assert_no_symbol_names(hint)


func test_player_2_has_green_fuse_and_sees_red_label() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	press(hall, "PlayerButton1")
	assert_contains(text_of(hall, "FuseTitle"), "green", "own fuse")
	var hint := text_of(hall, "LabelHint")
	assert_eq(frame_colour(hall), HallScript.UI_COLOURS["red"], "the order of which fuse (its frame)")
	assert_eq(label_pictures(hall), ["star", "bell", "snowflake", "tree"], "label symbols as pictures")
	assert_no_symbol_names(hint)


# ---------- clicking wires ----------

func test_clicked_wire_is_disabled_and_shown_in_order() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, ["white"])
	assert_eq(is_disabled(hall, "Wire_white"), true, "white disabled")
	assert_eq(is_disabled(hall, "Wire_blue"), false, "blue still enabled")
	assert_contains(text_of(hall, "ChosenLabel"), "white", "order so far")


func test_reset_clears_order() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, ["white", "blue"])
	press(hall, "ResetButton")
	assert_contains(text_of(hall, "ChosenLabel"), "click the wires", "order cleared")
	assert_eq(is_disabled(hall, "Wire_white"), false, "white enabled again")


func test_right_order_lights_the_room() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_contains(text_of(hall, "RoomLamp0"), "lit", "living/dining room lamp")
	assert_contains(text_of(hall, "RoomLamp1"), "dark", "bathroom lamp")
	assert_contains(text_of(hall, "Message"), "on", "message")
	assert_eq(text_of(hall, "PenaltyLabel"), "Penalty: 0 s", "no penalty")
	assert_eq(hall.puzzle["fuses"][0]["solved"], true, "rule state")


func test_wrong_order_costs_ten_seconds_each_time() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_WRONG)
	assert_eq(text_of(hall, "PenaltyLabel"), "Penalty: 10 s", "after 1 wrong try")
	assert_contains(text_of(hall, "Message"), "10 s", "message")
	assert_contains(text_of(hall, "RoomLamp0"), "dark", "lamp stays dark")
	assert_contains(text_of(hall, "ChosenLabel"), "click the wires", "order cleared")
	assert_eq(is_disabled(hall, "Wire_blue"), false, "wires usable again")
	click_wires(hall, RED_WRONG)
	assert_eq(text_of(hall, "PenaltyLabel"), "Penalty: 20 s", "after 2 wrong tries")


func test_solved_fuse_cannot_be_played_again() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	for colour in ["blue", "yellow", "white", "black"]:
		assert_eq(is_disabled(hall, "Wire_" + colour), true, colour + " disabled")
	assert_contains(text_of(hall, "ChosenLabel"), "already on", "status")


func test_switching_player_clears_half_done_order() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, ["white"])
	press(hall, "PlayerButton1")
	assert_contains(text_of(hall, "ChosenLabel"), "click the wires", "order cleared")
	assert_eq(is_disabled(hall, "Wire_white"), false, "white enabled for player 2")


func test_three_fuses_light_three_rooms() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	press(hall, "PlayerButton1")
	click_wires(hall, GREEN_RIGHT)
	press(hall, "PlayerButton2")
	click_wires(hall, GOLD_RIGHT)
	for i in 3:
		assert_contains(text_of(hall, "RoomLamp%d" % i), "lit", "lamp %d" % i)


# ---------- layout (bug from manual test 1: panel opened below the window) ----------

func test_everything_fits_in_the_window() -> void:
	tree.root.size = Vector2i(1152, 648)
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	await tree.process_frame  # let Godot arrange the boxes
	await tree.process_frame
	var window := Rect2(Vector2.ZERO, Vector2(1152, 648))
	for node_name in ["PenaltyLabel", "FusePanel", "RoomLamp2", "RoomTile2", "StairsButton", "Message"]:
		var node := find(hall, node_name)
		if node != null:
			assert_true(window.encloses(node.get_global_rect()), "%s inside the window, is %s" % [node_name, node.get_global_rect()])
	var penalty := find(hall, "PenaltyLabel")
	if penalty != null:
		assert_true(penalty.size.y < 40, "penalty counter is one line, height is %d" % penalty.size.y)


# ---------- online: each device shows only its own player (spec 04) ----------

func open_online_hall(net: Node) -> Node:
	var hall = HallScene.instantiate()
	hall.net = net
	tree.root.add_child(hall)
	return hall


# Playtest: the "still dark" message vanished at the next clock tick. Now it stays until
# something new happens in the game.
func test_the_dark_door_message_stays_until_something_happens() -> void:
	var room: Array = await make_started_room(47620)
	var hall := open_online_hall(room[0])
	hall._close_mission()
	hall._use_spot("bathroom")
	assert_contains(text_of(hall, "Message"), "still dark", "says why")
	room[0].game_changed.emit()  # the clock ticks: the game is sent again, nothing new
	assert_contains(text_of(hall, "Message"), "still dark", "still there after a tick")
	room[0].game["last_event"] = "Player 2 found something."
	room[0].game_changed.emit()
	assert_eq(text_of(hall, "Message"), "Player 2 found something.", "a real event replaces it")


func test_online_hall_shows_only_my_player() -> void:
	var room: Array = await make_started_room(47541)
	var a = room[1]
	var hall := open_online_hall(a)
	press(hall, "FuseBoxButton")
	var switch := find(hall, "PlayerButton0")
	assert_eq(switch != null and switch.is_visible_in_tree(), false, "no player switch")
	assert_contains(text_of(hall, "FuseTitle"), "Player 2", "who")
	assert_contains(text_of(hall, "FuseTitle"), "GREEN", "own fuse")
	if not a.game.is_empty():
		assert_eq(frame_colour(hall), HallScript.UI_COLOURS["red"], "sees the red fuse's order (its frame)")
		assert_eq(label_pictures(hall), FuseRules.label_for(a.game["puzzle"], 0), "label symbols as pictures")
		assert_no_symbol_names(text_of(hall, "LabelHint"))


func test_online_right_wires_light_the_room_on_every_device() -> void:
	var room: Array = await make_started_room(47542)
	var host_hall := open_online_hall(room[0])
	var a_hall := open_online_hall(room[1])
	press(a_hall, "FuseBoxButton")
	if not room[1].game.is_empty():
		click_wires(a_hall, room[1].game["puzzle"]["fuses"][1]["order"])
	var both_lit := func(): return "lit" in text_of(host_hall, "RoomLamp1") and "lit" in text_of(a_hall, "RoomLamp1")
	assert_true(await wait_until(both_lit), "bathroom lit on host and on Player 2")
	assert_contains(text_of(host_hall, "Message"), "Player 2 turned on the green fuse", "event on the host")


func test_online_wrong_wires_cost_penalty_on_every_device() -> void:
	var room: Array = await make_started_room(47543)
	var host_hall := open_online_hall(room[0])
	var b_hall := open_online_hall(room[2])
	press(b_hall, "FuseBoxButton")
	if not room[2].game.is_empty():
		var wrong: Array = room[2].game["puzzle"]["fuses"][2]["order"].duplicate()
		wrong.reverse()
		click_wires(b_hall, wrong)
	var both_10 := func(): return text_of(host_hall, "PenaltyLabel") == "Penalty: 10 s" and text_of(b_hall, "PenaltyLabel") == "Penalty: 10 s"
	assert_true(await wait_until(both_10), "10 s on host and on Player 3")
	assert_contains(text_of(b_hall, "Message"), "Player 3: wrong order", "event on Player 3")


# ---------- atmosphere (spec 05) ----------

func tile_colour(hall: Node, index: int) -> Color:
	var tile := find(hall, "RoomTile%d" % index)
	if tile == null:
		return Color.TRANSPARENT
	return tile.get_theme_stylebox("panel").bg_color


func test_flicker_gets_weaker_with_each_fuse() -> void:
	var strengths := []
	for lit in [0, 1, 2, 3]:
		strengths.append(HallScript.flicker_strength(lit))
	assert_true(strengths[0] > strengths[1] and strengths[1] > strengths[2] and strengths[2] > strengths[3], "weaker each time: %s" % [strengths])
	assert_eq(strengths[3], 0.0, "no flicker with all 3 fuses on")


func test_hall_flickers_until_all_fuses_are_on() -> void:
	var hall := open_hall()
	assert_eq(hall.flicker_active(), true, "flickers at the start")
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_eq(hall.flicker_active(), true, "still flickers with 1 fuse on")
	press(hall, "PlayerButton1")
	click_wires(hall, GREEN_RIGHT)
	press(hall, "PlayerButton2")
	click_wires(hall, GOLD_RIGHT)
	assert_eq(hall.flicker_active(), false, "stops with all 3 fuses on")
	var overlay := find(hall, "FlickerOverlay")
	assert_eq(overlay != null and overlay.color.a == 0.0, true, "overlay fully clear")


func test_flicker_overlay_lets_clicks_through() -> void:
	var overlay := find(open_hall(), "FlickerOverlay")
	assert_eq(overlay != null and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, true, "ignores the mouse")


func test_room_tiles_light_up_with_their_fuse() -> void:
	var hall := open_hall()
	var dark := tile_colour(hall, 0)
	assert_eq(tile_colour(hall, 1), dark, "all tiles dark at the start")
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_eq(tile_colour(hall, 0), HallScript.ROOM_LIT, "living/dining room tile lit")
	assert_eq(tile_colour(hall, 1), HallScript.ROOM_DARK, "bathroom tile still dark")


# Bug from manual test 1 (spec 05): flicker was too strong and too restless.

func test_flicker_is_gentle() -> void:
	assert_true(HallScript.flicker_strength(0) <= 0.3, "at most 30 %% dark, is %s" % HallScript.flicker_strength(0))


func test_flicker_comes_in_short_bursts_with_calm_pauses() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in [1, 2, 3, 4, 5]:
		rng.seed = seed_value
		var steps: Array = HallScript.flicker_cycle(rng, 0.3)
		assert_eq(steps[0][0], 0.0, "starts calm")
		var pause: float = steps[0][1]
		assert_true(pause >= Settings.FLICKER_PAUSE_MIN_SECONDS and pause <= Settings.FLICKER_PAUSE_MAX_SECONDS, "calm pause, is %s s" % pause)
		var dips := steps.filter(func(step): return step[0] > 0.0)
		assert_true(dips.size() >= 2 and dips.size() <= 4, "2 to 4 dips, is %d" % dips.size())
		for dip in dips:
			assert_true(dip[1] <= 0.1, "dip is short, is %s s" % dip[1])
			assert_true(dip[0] <= 0.3, "dip not darker than the strength, is %s" % dip[0])


# ---------- doors and stairs (spec 07) ----------

func test_doors_are_dark_until_their_fuse_is_on() -> void:
	var hall := open_hall()
	for place in ["living_room", "bathroom", "bedroom"]:
		assert_eq(is_disabled(hall, "Door_" + place), true, place + " door disabled")
		assert_contains(text_of(hall, "Door_" + place), "dark", place + " door text")
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_eq(is_disabled(hall, "Door_living_room"), false, "living room door open")
	assert_eq(is_disabled(hall, "Door_bathroom"), true, "bathroom still dark")


func test_stairs_need_all_three_fuses() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	press(hall, "PlayerButton1")
	click_wires(hall, GREEN_RIGHT)
	assert_eq(is_disabled(hall, "StairsButton"), true, "2 fuses: stairs dark")
	press(hall, "PlayerButton2")
	click_wires(hall, GOLD_RIGHT)
	assert_eq(is_disabled(hall, "StairsButton"), false, "3 fuses: stairs open")


func test_door_alone_explains_that_walking_needs_the_full_game() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	press(hall, "Door_living_room")
	assert_contains(text_of(hall, "Message"), "full game", "explanation")


func test_online_door_walks_the_team() -> void:
	var room: Array = await make_started_room(47561)
	var a = room[1]
	var hall := open_online_hall(a)
	press(hall, "FuseBoxButton")
	if not a.game.is_empty():
		click_wires(hall, a.game["puzzle"]["fuses"][1]["order"])
	await wait_until(func(): return not is_disabled(hall, "Door_bathroom"))
	press(hall, "Door_bathroom")
	assert_true(await wait_until(func(): return room[0].game.get("location") == "bathroom"), "host: team in the bathroom")


# ---------- artwork, spots and close-ups (spec 08) ----------

const SPOT_ORDER := ["fuse_box", "living_room", "wreath", "bathroom", "attic", "bedroom", "house_plan"]
const SPOT_NODES := ["FuseBoxButton", "Door_living_room", "StoryWreath", "Door_bathroom", "StairsButton", "Door_bedroom", "HousePlanButton"]


# Like a real key press: through the viewport, so focused buttons get the chance
# to swallow it first (bug from manual test 2).
func key(hall: Node, action: String) -> void:
	for down in [true, false]:  # a real key goes down and comes up again
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		tree.root.push_input(event)


func texture_file(hall: Node, node_name: String) -> String:
	var node := find(hall, node_name)
	if node == null or not "texture" in node or node.texture == null:
		return ""
	return node.texture.resource_path.get_file()


# The colour you actually see: the picture's visible pixels on average,
# times the node's tint (modulate, self_modulate).
func shown_colour(hall: Node, node_name: String) -> Color:
	var node := find(hall, node_name)
	if node == null or not "texture" in node or node.texture == null:
		return Color.BLACK
	var image: Image = node.texture.get_image()
	if image.is_compressed():
		image.decompress()
	var sum := Color(0, 0, 0, 0)
	var count := 0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.5:
				sum += pixel
				count += 1
	if count == 0:
		return Color.BLACK
	var average := Color(sum.r / count, sum.g / count, sum.b / count)
	var tint: Color = node.modulate * node.self_modulate
	return Color(minf(average.r * tint.r, 1.0), minf(average.g * tint.g, 1.0), minf(average.b * tint.b, 1.0))


func same_colour(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.06 and absf(a.g - b.g) < 0.06 and absf(a.b - b.b) < 0.06


func is_shown(hall: Node, node_name: String) -> bool:
	var node := find(hall, node_name)
	return node != null and node.is_visible_in_tree()


func test_hall_picture_is_the_background() -> void:
	assert_eq(texture_file(open_hall(), "Background"), "room_hall.webp", "background")


func test_all_spots_inside_the_picture() -> void:
	var hall := open_hall()
	var window := Rect2(Vector2.ZERO, Vector2(1152, 648))
	for node_name in SPOT_NODES:
		var spot := find(hall, node_name)
		if spot != null:
			assert_true(window.encloses(spot.get_global_rect()), node_name + " inside the window")


func test_arrows_move_the_highlight_from_spot_to_spot() -> void:
	var hall := open_hall()
	var seen := [hall.highlighted_spot()]
	for i in SPOT_ORDER.size() - 1:
		key(hall, "ui_right")
		seen.append(hall.highlighted_spot())
	assert_eq(seen, SPOT_ORDER, "left to right")
	key(hall, "ui_right")
	assert_eq(hall.highlighted_spot(), "house_plan", "stops at the last spot")
	key(hall, "ui_left")
	assert_eq(hall.highlighted_spot(), "bedroom", "one back")


func test_enter_opens_the_fuse_box_and_escape_closes_it() -> void:
	var hall := open_hall()
	key(hall, "ui_accept")
	assert_eq(is_shown(hall, "FusePanel"), true, "fuse box open")
	assert_eq(texture_file(hall, "FuseBoxPicture"), "ui_fuse_box.webp", "close-up picture")
	key(hall, "ui_cancel")
	assert_eq(is_shown(hall, "FusePanel"), false, "fuse box closed")


func test_house_plan_opens_and_closes() -> void:
	var hall := open_hall()
	press(hall, "HousePlanButton")
	assert_eq(is_shown(hall, "HousePlanPanel"), true, "plan open")
	assert_eq(texture_file(hall, "HousePlanPicture"), "ui_house_plan.webp", "plan picture")
	key(hall, "ui_cancel")
	assert_eq(is_shown(hall, "HousePlanPanel"), false, "plan closed by Esc")
	press(hall, "HousePlanButton")
	press(hall, "BackFromPlan")
	assert_eq(is_shown(hall, "HousePlanPanel"), false, "plan closed by Back")


func test_dark_door_by_key_explains_which_fuse() -> void:
	var hall := open_hall()
	for i in 3:
		key(hall, "ui_right")  # living room, wreath, bathroom door (spec 25)
	key(hall, "ui_accept")
	assert_contains(text_of(hall, "Message"), "green fuse", "explanation")


# The modern fuse box (second test round): a solved fuse flips its breaker up, cut from
# the "all on" picture, so it lines up exactly with the "all off" box.
func test_a_solved_fuse_flips_its_breaker_up() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	assert_eq(texture_file(hall, "FuseBoxPicture"), "ui_fuse_box.webp", "the box, all breakers down")
	assert_eq(is_shown(hall, "BreakerOn_red"), false, "red still down")
	click_wires(hall, RED_RIGHT)
	assert_eq(is_shown(hall, "BreakerOn_red"), true, "red flipped up")
	var breaker: TextureRect = find(hall, "BreakerOn_red")
	assert_true(breaker.texture is AtlasTexture, "a piece of the 'all on' picture")
	assert_eq(breaker.texture.atlas.resource_path.get_file(), "ui_fuse_box_on.webp", "from the 'on' picture")
	assert_eq(is_shown(hall, "BreakerOn_green"), false, "green still down")


func test_torn_label_and_order_show_pictures() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	var expected := ["bell", "snowflake", "star", "tree"]  # gold label, seen by Player 1
	for i in 4:
		assert_eq(texture_file(hall, "LabelSymbol%d" % i), "sym_%s.png" % expected[i], "label symbol %d" % i)
	click_wires(hall, ["white"])
	var bar := find(hall, "ChosenWire0")
	var bar_colour: Color = bar.get_theme_stylebox("panel").bg_color if bar != null else Color.TRANSPARENT
	assert_eq(bar_colour, HallScript.UI_COLOURS["white"], "first chosen wire as a white bar")
	assert_eq(is_shown(hall, "ChosenWire0"), true, "first bar shown")
	assert_eq(is_shown(hall, "ChosenWire1"), false, "nothing chosen second yet")
	for colour in ["blue", "yellow", "white", "black"]:
		assert_eq(text_of(hall, "WireName_" + colour), colour, "name above the %s cable" % colour)


func test_wires_sit_over_the_cables_blue_yellow_white_black() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	await wait_frames(2)
	var xs := []
	for colour in ["blue", "yellow", "white", "black"]:
		var wire := find(hall, "Wire_" + colour)
		xs.append(wire.get_global_rect().position.x if wire != null else -1.0)
	var sorted_xs := xs.duplicate()
	sorted_xs.sort()
	assert_eq(xs, sorted_xs, "left to right")
	# Over the four cables of the modern ui_fuse_box.webp: picture pixels x 535 to 840, y 465 to 720.
	for colour in ["blue", "yellow", "white", "black"]:
		var wire := find(hall, "Wire_" + colour)
		if wire != null:
			var r := in_picture_pixels(hall, "FuseBoxPicture", wire)
			assert_true(Rect2(535, 465, 305, 255).encloses(r), "%s over the cables, is %s" % [colour, r])


func test_keyboard_only_solves_a_fuse() -> void:
	var hall := open_hall()
	key(hall, "ui_accept")  # opens the fuse box
	for colour in RED_RIGHT:
		var steps := 0
		while hall.highlighted_wire() != colour and steps < 8:
			key(hall, "ui_right" if steps < 4 else "ui_left")
			steps += 1
		key(hall, "ui_accept")
	assert_contains(text_of(hall, "RoomLamp0"), "lit", "living room lit by keys only")


# ---------- polish after manual test 2 (spec 08b) ----------

const PICTURE := Vector2(1376, 768)


# A node's rect measured in the pixels of the picture it sits on.
func in_picture_pixels(hall: Node, picture_name: String, node: Control) -> Rect2:
	var picture := find(hall, picture_name)
	if picture == null:
		return Rect2()
	var p: Rect2 = picture.get_global_rect()
	var scale := p.size.x / PICTURE.x
	var r := node.get_global_rect()
	return Rect2((r.position - p.position) / scale, r.size / scale)


func near(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < 3.0 and a.size.distance_to(b.size) < 3.0


# Bug 1: in a window of another shape the fields slid off the picture.
func test_spots_and_fields_stay_on_the_picture_in_any_window_shape() -> void:
	for window in [Vector2i(1152, 648), Vector2i(1400, 900), Vector2i(1800, 700)]:
		var hall := open_hall()
		tree.root.size = window
		press(hall, "HousePlanButton")
		await wait_frames(3)
		var spot := find(hall, "FuseBoxButton")
		if spot != null:
			var r := in_picture_pixels(hall, "Background", spot)
			assert_true(near(r, HallScript.SPOTS[0]["rect"]), "fuse box spot in %s window: %s" % [window, r])
		# The whole picture stays visible: no spot is cut off at the window's edge.
		var visible := tree.root.get_visible_rect().grow(1)
		for spot_info in HallScript.SPOTS:
			var node := find(hall, spot_info["node"])
			if node != null:
				assert_true(visible.encloses(node.get_global_rect()), "%s fully visible in %s window" % [spot_info["node"], window])
		var tile := find(hall, "RoomTile1")
		if tile != null:
			var r := in_picture_pixels(hall, "HousePlanPicture", tile)
			assert_true(near(r, HallScript.PLAN_ROOMS[1]), "bathroom field in %s window: %s" % [window, r])
		hall.free()
	tree.root.size = Vector2i(1152, 648)


func test_pictures_keep_their_shape() -> void:
	var hall := open_hall()
	tree.root.size = Vector2i(1400, 900)
	await wait_frames(3)
	var picture := find(hall, "Background")
	if picture != null:
		var size: Vector2 = picture.get_global_rect().size
		assert_true(absf(size.x / size.y - PICTURE.x / PICTURE.y) < 0.01, "aspect kept, size %s" % size)
	tree.root.size = Vector2i(1152, 648)


# Bug 2: after a mouse click the clicked button kept the keys (arrows moved
# Godot's own focus, Enter pressed the clicked button again).
# A real click gives a button the focus if it can take it; click() does the same.
func click(hall: Node, node_name: String) -> void:
	var button := find(hall, node_name)
	if button != null:
		if button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus()
		button.pressed.emit()


func test_keys_still_work_after_a_mouse_click() -> void:
	var hall := open_hall()
	click(hall, "PlayerButton1")
	key(hall, "ui_right")
	assert_eq(hall.highlighted_spot(), "living_room", "right arrow moved the highlight after clicking Player 2")
	click(hall, "FuseBoxButton")
	assert_eq(is_shown(hall, "FusePanel"), true, "the click opened the fuse box")
	click(hall, "Wire_yellow")
	key(hall, "ui_right")
	key(hall, "ui_right")
	assert_eq(hall.highlighted_wire(), "white", "arrows moved the cable highlight after the click")
	key(hall, "ui_accept")
	assert_eq(text_of(hall, "ChosenLabel"), "Your order: yellow, white", "Enter chose the highlighted cable")
	click(hall, "ResetButton")
	key(hall, "ui_accept")
	assert_eq(text_of(hall, "ChosenLabel"), "Your order: white", "Enter after clicking Reset chooses, it does not reset again")
	key(hall, "ui_cancel")
	assert_eq(is_shown(hall, "FusePanel"), false, "Esc closed the fuse box")


# Clean house plan: short names, exact fields.
func test_room_fields_name_the_room_and_its_light() -> void:
	var hall := open_hall()
	assert_eq(text_of(hall, "RoomLamp0"), "Living room\ndark", "living room field")
	assert_eq(text_of(hall, "RoomLamp1"), "Bathroom\ndark", "bathroom field")
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_eq(text_of(hall, "RoomLamp0"), "Living room\nlit", "after the red fuse")


func test_legend_sits_inside_the_plans_box() -> void:
	var hall := open_hall()
	press(hall, "HousePlanButton")
	await wait_frames(3)
	for symbol in ["star", "bell", "tree", "snowflake"]:
		var entry := find(hall, "LegendEntry_" + symbol)
		if entry != null:
			var r := in_picture_pixels(hall, "HousePlanPicture", entry)
			assert_true(HallScript.LEGEND_BOX.encloses(r), "%s entry inside the box, is %s" % [symbol, r])


# Change after manual test 3: no dragging, no contacts on the door, no lines.
# The cables are clicked, and the order of the clicks is the order tried.
func test_cables_are_only_clicked_in_order() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	var wire := find(hall, "Wire_blue")
	var drag_data = wire.call("_get_drag_data", Vector2.ZERO) if wire != null and wire.has_method("_get_drag_data") else null
	assert_eq(drag_data, null, "a cable can't be dragged")
	assert_true(hall.find_child("Contact1", true, false) == null, "no contacts on the door")
	click_wires(hall, ["white", "blue"])
	assert_eq(text_of(hall, "ChosenLabel"), "Your order: white, blue", "the order of the clicks")
	assert_true(hall.find_child("Connection_white", true, false) == null, "no connection lines")


# Spec 08b, wish 4: symbols in colour, each its own fixed colour, the same on
# the torn label and in the legend.
func test_symbols_are_shown_in_their_own_colour() -> void:
	var hall := open_hall()
	var wanted := {"star": Color("f5c242"), "bell": Color("d64541"), "tree": Color("3fa34d"), "snowflake": Color("7cc6ea")}
	for symbol in wanted:
		var colour := shown_colour(hall, "LegendSymbol_" + symbol)
		assert_true(same_colour(colour, wanted[symbol]), "legend %s is %s, wanted %s" % [symbol, colour.to_html(false), wanted[symbol].to_html(false)])
	press(hall, "FuseBoxButton")
	for i in 4:
		var symbol := texture_file(hall, "LabelSymbol%d" % i).trim_prefix("sym_").trim_suffix(".png")
		assert_true(wanted.has(symbol), "label symbol %d is a symbol picture: %s" % [i, symbol])
		if wanted.has(symbol):
			var colour := shown_colour(hall, "LabelSymbol%d" % i)
			assert_true(same_colour(colour, wanted[symbol]), "label symbol %d (%s) is %s" % [i, symbol, colour.to_html(false)])


# Hall polish (first full test round): the symbols do not say whose fuse they are for.
# Only their frame is in that fuse's colour, so players try them first and then work it out.
func test_the_order_is_framed_in_the_colour_of_its_fuse() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	var seen := {0: "gold", 1: "red", 2: "green"}  # player -> the fuse whose order they see
	for player in seen:
		press(hall, "PlayerButton%d" % player)
		var fuse: String = seen[player]
		var frame := find(hall, "LabelFrame")
		var border: Color = frame.get_theme_stylebox("panel").border_color if frame != null else Color.TRANSPARENT
		assert_eq(border, HallScript.UI_COLOURS[fuse], "player %d: frame in %s" % [player + 1, fuse])
		assert_true(hall.find_child("LabelFuse", true, false) == null, "no small fuse icon (it confused players)")
		assert_true(not text_of(hall, "LabelHint").contains(fuse), "player %d: the fuse is not named" % [player + 1])
		assert_contains(text_of(hall, "LabelHint"), "Not every order you see is meant for you", "the quiet hint")
		assert_true(not text_of(hall, "LabelHint").to_lower().contains("torn"), "no torn label")


# Wish after manual test 4: a bit more room under the panel's title.
func test_more_room_under_the_fuse_panel_title() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	await wait_frames(3)
	var title := find(hall, "FuseTitle")
	var hint := find(hall, "LabelHint")
	if title != null and hint != null:
		var gap: float = hint.get_global_rect().position.y - title.get_global_rect().end.y
		assert_true(gap >= 18, "gap under the title is %d px, wanted at least 18" % gap)


# ---------- walking figures (spec 19) ----------

func key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed
	return event


func test_online_hall_shows_the_figures_and_walks_with_wasd() -> void:
	var room: Array = await make_started_room(47623)
	var hall := open_online_hall(room[1])
	await wait_frames(2)
	for player in 3:
		var figure: TextureRect = find(hall, "Figure_%d" % player)
		assert_true(figure != null and figure.texture != null, "figure of Player %d" % (player + 1))
	var layer: Node = find(hall, "WalkLayer")
	if layer == null:
		return
	layer._unhandled_key_input(key_event(KEY_D, true))
	assert_true(await wait_until(func(): return room[0].game["figures"][1]["dx"] == 1.0), "D: walking right")
	layer._unhandled_key_input(key_event(KEY_W, true))
	assert_true(await wait_until(func(): return room[0].game["figures"][1]["dy"] < 0.0), "W: walking into the room")
	layer._unhandled_key_input(key_event(KEY_D, false))
	layer._unhandled_key_input(key_event(KEY_W, false))
	assert_true(await wait_until(func(): return room[0].game["figures"][1]["dx"] == 0.0 and room[0].game["figures"][1]["dy"] == 0.0), "keys up: standing")


# Spec 27: the figure in the house wears the chosen accessory.
func test_figures_wear_their_accessory() -> void:
	var room: Array = await make_started_room(47626)
	var hall := open_online_hall(room[1])
	await wait_frames(2)
	room[1].game["characters"] = {0: {"character": "santa", "colour": "green", "accessory": "nose"}}
	room[1].game_changed.emit()
	assert_eq(texture_file(hall, "Figure_0"), "char_santa_green_nose.png", "Santa with the red nose")


func test_f3_shows_the_floor_outline() -> void:
	var room: Array = await make_started_room(47625)
	var hall := open_online_hall(room[0])
	await wait_frames(2)
	var layer: Node = find(hall, "WalkLayer")
	var outline: Control = find(hall, "FloorOutline")
	if layer == null or outline == null:
		return
	assert_eq(outline.visible, false, "hidden at first")
	layer._unhandled_key_input(key_event(KEY_F3, true))
	assert_eq(outline.visible, true, "F3 shows it")
	layer._unhandled_key_input(key_event(KEY_F3, true))
	assert_eq(outline.visible, false, "F3 hides it")


func test_a_far_figure_is_drawn_smaller_than_a_near_one() -> void:
	var room: Array = await make_started_room(47624)
	var hall := open_online_hall(room[0])
	await wait_frames(2)
	var figure: TextureRect = find(hall, "Figure_0")
	var near_height: float = figure.size.y
	room[0].game["figures"][0]["y"] = room[0].game["figures"][0]["y"] - 100.0  # further back, still on the floor
	hall.find_child("WalkLayer", true, false)._refresh()
	assert_true(figure.size.y < near_height, "smaller further back: %s < %s" % [figure.size.y, near_height])


func test_the_offline_hall_has_no_figures() -> void:
	var hall := open_hall()
	assert_true(hall.find_child("Figure_0", true, false) == null, "no network: no figures")


# ---------- hall polish (first full test round) ----------

func test_a_wrong_order_sparks_and_asks_whose_order_it_is() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_WRONG)
	assert_true("sfx_spark.mp3" in hall.sounds_played, "sparks")
	assert_contains(text_of(hall, "FuseHint"), "really meant for", "first hint")
	assert_true(not text_of(hall, "FuseHint").contains("gold"), "the colour is not named yet")


# The rescue hint comes late (help in three levels): after Settings.RESCUE_TRIES wrong orders.
func test_the_rescue_hint_names_the_fuse_only_after_many_tries() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	for i in Settings.RESCUE_TRIES - 1:
		click_wires(hall, RED_WRONG)
	assert_true(not text_of(hall, "FuseHint").contains("GOLD"), "not yet")
	click_wires(hall, RED_WRONG)
	assert_contains(text_of(hall, "FuseHint"), "GOLD", "now it says whose order it is")


func test_after_your_own_fuse_the_order_is_still_needed() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_contains(text_of(hall, "FuseHint"), "someone else might need them", "the order is for someone else")


func test_the_figures_hide_while_a_close_up_is_open() -> void:
	var hall := open_hall()
	var figures := Control.new()  # stands in for the walking layer (only online)
	hall.walking = figures
	press(hall, "FuseBoxButton")
	assert_eq(figures.visible, false, "hidden behind the fuse box")
	press(hall, "BackFromFuseBox")
	assert_eq(figures.visible, true, "back in the hall")
	press(hall, "HousePlanButton")
	assert_eq(figures.visible, false, "hidden behind the house plan")
	figures.free()


func test_the_doll_on_the_stairs_turns_her_head_every_time() -> void:
	var hall := open_hall()
	assert_eq(texture_file(hall, "Doll"), "prop_doll.png", "she sits on the stairs")
	var stairs: Button = find(hall, "StairsButton")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false  # a click on the dark stairs (released)
	stairs.gui_input.emit(click)
	assert_contains(text_of(hall, "Message"), "pitch dark", "the stairs are dark")
	assert_eq(texture_file(hall, "Doll"), "prop_doll_turned.png", "she turns her head")
	assert_eq(hall.sounds_played.count("sfx_creak.mp3"), 1, "with a creak")
	hall._doll_turns_back()  # after a moment she looks away again
	stairs.gui_input.emit(click)
	assert_eq(texture_file(hall, "Doll"), "prop_doll_turned.png", "and turns again on the next click")
	assert_eq(hall.sounds_played.count("sfx_creak.mp3"), 2, "creaking again")


# ---------- sound pack (spec 22) ----------

func test_right_order_clicks_the_fuse_in() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	assert_eq(hall.sounds_played.count("sfx_fuse_click.mp3"), 1, "one click: %s" % [hall.sounds_played])
	assert_eq(hall.sounds_played.has("sfx_spark.mp3"), false, "no sparks")


func test_wrong_order_does_not_click() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_WRONG)
	assert_eq(hall.sounds_played.has("sfx_fuse_click.mp3"), false, "no click for a wrong order")


func test_online_everyone_hears_the_fuse_click() -> void:
	var room: Array = await make_started_room(47641)
	var hall_a := open_online_hall(room[1])
	var hall_b := open_online_hall(room[2])
	room[1].send_action("try_fuse", {"wires": room[1].game["puzzle"]["fuses"][1]["order"].duplicate()})
	var both_hear := func(): return hall_a.sounds_played.has("sfx_fuse_click.mp3") and hall_b.sounds_played.has("sfx_fuse_click.mp3")
	assert_true(await wait_until(both_hear), "Player 2 and Player 3 hear the click")


func test_coming_back_to_the_hall_replays_no_click() -> void:
	var room: Array = await make_started_room(47642)
	room[0].send_action("try_fuse", {"wires": room[0].game["puzzle"]["fuses"][0]["order"].duplicate()})
	await wait_until(func(): return room[1].game["puzzle"]["fuses"][0]["solved"])
	var hall := open_online_hall(room[1])
	var played_before: int = room[1].game.get("seconds_played", 0)
	room[0].advance_clock(1.0)  # the next change of the game (here: one second of the clock)
	await wait_until(func(): return room[1].game.get("seconds_played", 0) > played_before)
	assert_eq(hall.sounds_played.has("sfx_fuse_click.mp3"), false, "an old fuse does not click again")


func test_the_fuse_click_is_a_short_real_click() -> void:
	var click: AudioStreamMP3 = load("res://assets/sounds/sfx_fuse_click.mp3")
	var length := click.get_length() if click != null else 0.0
	assert_true(length > 0.1 and length < 0.5, "a short click, not the 0.52 s silent placeholder: %.2f s" % length)



# ---------- the mission card (second test round) ----------

func test_the_mission_card_shows_when_the_team_enters_the_hall() -> void:
	HallScript.forget_mission()  # as at the start of a new game
	var hall := open_hall()
	assert_eq(is_shown(hall, "MissionCard"), true, "shown at first")
	var text := text_of(hall, "MissionText")
	for part in ["Your mission", "three presents", "one team", "every room first", "20 minutes"]:
		assert_contains(text, part, "the card says: " + part)
	press(hall, "MissionGo")
	assert_eq(is_shown(hall, "MissionCard"), false, "closed with Let's go")
	press(hall, "MissionButton")
	assert_eq(is_shown(hall, "MissionCard"), true, "the ? opens it again")


func test_the_mission_card_shows_only_on_the_first_visit() -> void:
	HallScript.forget_mission()
	var hall := open_hall()
	press(hall, "MissionGo")
	var again := open_hall()  # the team comes back from a room
	assert_eq(is_shown(again, "MissionCard"), false, "not again")


# ---------- story objects (spec 25) ----------

func story_spot(name: String) -> Dictionary:
	for spot in HallScript.SPOTS:
		if spot["name"] == name:
			return spot
	return {}


func test_story_object_sits_on_the_wreath() -> void:
	var hall := open_hall()
	await wait_frames(2)
	assert_eq(story_spot("lantern"), {}, "only the wreath (the lantern was dropped)")
	for pair in [["wreath", "StoryWreath", Rect2(198, 146, 112, 250)]]:
		var spot := story_spot(pair[0])
		assert_eq(spot.get("rect"), pair[2], pair[0] + " measured on the picture")
		var button: Button = hall.find_child(pair[1], true, false)
		assert_true(button != null, pair[1] + " exists")
		if button != null:
			assert_true(near(in_picture_pixels(hall, "Background", button), pair[2]), pair[1] + " on its object")
			assert_eq(button.text, "", "no name on the object")
			assert_true(button.tooltip_text != "", "a hint on hover")
			assert_eq(button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "the hand cursor")
	var door: Button = hall.find_child("Door_living_room", true, false)
	assert_eq(door.mouse_default_cursor_shape if door != null else -1, Control.CURSOR_POINTING_HAND, "every spot shows the hand")
	var wreath: Node = hall.find_child("StoryWreath", true, false)
	if wreath != null and door != null:
		assert_true(wreath.get_index() > door.get_index(), "the wreath lies on top of the door")


func test_the_wreath_tells_who_jingles_was() -> void:
	var hall := open_hall()
	var before: Dictionary = hall.puzzle.duplicate(true)
	var message_before := text_of(hall, "Message")
	press(hall, "StoryWreath")
	assert_eq(is_shown(hall, "StoryCard"), true, "a note appears")
	assert_contains(text_of(hall, "StoryText"), "For Jingles, my best little elf", "the tag")
	assert_true(hall.sounds_played.has("sfx_easter_egg.mp3"), "faint bells")
	assert_eq(hall.puzzle, before, "nothing changes in the puzzle")
	assert_eq(hall.penalty_total, 0, "it costs no time")
	assert_eq(text_of(hall, "Message"), message_before, "the door underneath was not used")


func test_the_story_note_closes_with_keys() -> void:
	var hall := open_hall()
	press(hall, "StoryWreath")
	key(hall, "ui_cancel")
	assert_eq(is_shown(hall, "StoryCard"), false, "Esc closes it")
	press(hall, "StoryWreath")
	key(hall, "ui_accept")
	assert_eq(is_shown(hall, "StoryCard"), false, "Enter closes it")
	assert_eq(is_shown(hall, "FusePanel"), false, "and does nothing else")


func test_arrows_and_enter_reach_the_wreath() -> void:
	var hall := open_hall()
	key(hall, "ui_right")
	key(hall, "ui_right")
	assert_eq(hall.highlighted_spot(), "wreath", "after the living room door")
	key(hall, "ui_accept")
	assert_eq(is_shown(hall, "StoryCard"), true, "Enter shows the note")


func test_online_a_story_note_stays_on_this_device() -> void:
	var room: Array = await make_started_room(47661)
	var hall := open_online_hall(room[1])
	var event_before: String = room[0].game.get("last_event", "")
	press(hall, "StoryWreath")
	await wait_frames(5)
	assert_eq(is_shown(hall, "StoryCard"), true, "Player 2 reads it")
	assert_eq(room[0].game.get("last_event", ""), event_before, "nothing sent to the host")


# A real mouse click, through Godot's own input (down and up again).
func real_click(at: Vector2) -> void:
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		click.global_position = at
		tree.root.push_input(click)


func test_real_clicks_wreath_note_and_door() -> void:
	var hall := open_hall()
	press(hall, "MissionGo")  # the mission note first
	await wait_frames(2)
	var scale := 1152.0 / 1376.0
	var top := (648.0 - 768.0 * scale) / 2
	real_click(Vector2(254, 271) * scale + Vector2(0, top))  # the middle of the wreath
	assert_eq(is_shown(hall, "StoryCard"), true, "a click on the wreath shows its note")
	real_click(Vector2(1000, 600))
	assert_eq(is_shown(hall, "StoryCard"), false, "a click anywhere closes it")
	real_click(Vector2(250, 600) * scale + Vector2(0, top))  # the lower part of the door
	assert_eq(is_shown(hall, "StoryCard"), false, "the door is not the wreath")
	assert_contains(text_of(hall, "Message"), "red fuse", "the door below the wreath is still the door")


# ---------- playtest fixes (spec 29) ----------

func test_the_order_symbols_spread_evenly_over_the_frame() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	await wait_frames(3)
	var frame: Control = hall.find_child("LabelFrame", true, false)
	var centres := []
	for i in 4:
		var symbol: Control = hall.find_child("LabelSymbol%d" % i, true, false)
		centres.append(symbol.get_global_rect().get_center().x)
	var r := frame.get_global_rect()
	var gap: float = centres[1] - centres[0]
	for i in range(1, 3):
		assert_true(absf((centres[i + 1] - centres[i]) - gap) < 2, "even gaps")
	var left: float = centres[0] - r.position.x
	var right: float = r.end.x - centres[3]
	assert_true(absf(left - right) < 4, "as much room left as right: %d / %d" % [left, right])
	assert_true(gap > 70, "spread over the frame, not packed at the left: gap %d" % gap)


func test_the_wreath_greeting_has_its_own_line() -> void:
	var hall := open_hall()
	press(hall, "StoryWreath")
	assert_contains(text_of(hall, "StoryText"), "my best little elf.\nMerry Christmas! – S.", "a new line before the greeting")


func test_the_mission_card_stays_away_after_a_fuse_is_solved() -> void:
	HallScript.forget_mission()
	var room: Array = await make_started_room(47671)
	var hall := open_online_hall(room[1])
	assert_eq(is_shown(hall, "MissionCard"), true, "shown at the first visit")
	press(hall, "MissionGo")
	room[1].send_action("try_fuse", {"wires": room[1].game["puzzle"]["fuses"][1]["order"].duplicate()})
	await wait_until(func(): return room[1].game["puzzle"]["fuses"][1]["solved"])
	hall.free()
	var again := open_online_hall(room[1])  # the team comes back from a room
	assert_eq(is_shown(again, "MissionCard"), false, "not again, even with a fuse solved")


func test_figures_step_aside_while_the_wreath_note_is_open() -> void:
	var room: Array = await make_started_room(47672)
	var hall := open_online_hall(room[1])
	press(hall, "MissionGo")
	var walking: Node = hall.get("walking")
	assert_true(walking != null and walking.visible, "the figures are in the hall")
	press(hall, "StoryWreath")
	assert_eq(walking.visible if walking != null else true, false, "they step aside for the note")
	key(hall, "ui_cancel")
	assert_eq(walking.visible if walking != null else false, true, "and come back")



# ---------- single player (second test round) ----------

func open_hall_alone() -> Node:
	tree.root.size = Vector2i(1152, 648)
	var hall = HallScene.instantiate()
	hall.seed_value = 42
	hall.solo = true
	tree.root.add_child(hall)
	hall._close_mission()
	return hall


func test_alone_the_fuse_box_says_the_order_is_hidden() -> void:
	var hall := open_hall_alone()
	press(hall, "FuseBoxButton")
	assert_contains(text_of(hall, "FuseTitle"), "all three", "one player, all fuses")
	assert_contains(text_of(hall, "LabelHint"), "hidden somewhere in the hall", "no teammate reads it out")
	assert_eq(is_shown(hall, "LabelFrame"), false, "no order shown in the box")


func test_alone_the_doll_on_the_stairs_has_the_note() -> void:
	var hall := open_hall_alone()
	assert_eq(is_shown(hall, "DollNote"), true, "a note lies in her lap")
	press(hall, "DollNote")
	assert_eq(is_shown(hall, "NotePanel"), true, "the note opens")
	var expected := ["star", "bell", "snowflake", "tree"]  # the red fuse's order, seed 42
	for i in 4:
		assert_eq(texture_file(hall, "NoteSymbol%d" % i), "sym_%s.png" % expected[i], "note symbol %d" % i)
	press(hall, "BackFromNote")
	assert_eq(is_shown(hall, "NotePanel"), false, "closed again")


func test_alone_one_right_order_lights_every_room() -> void:
	var hall := open_hall_alone()
	press(hall, "FuseBoxButton")
	click_wires(hall, RED_RIGHT)
	for colour in ["red", "green", "gold"]:
		assert_eq(is_shown(hall, "BreakerOn_" + colour), true, colour + " breaker up")
	for i in 3:
		assert_contains(text_of(hall, "RoomLamp%d" % i), "lit", "room %d lit" % i)


# Playtest: the first (blue) wire always had a yellow frame. The frame shows only once
# the arrow keys are used (the mouse shows its own frame on hover).
func test_no_wire_is_framed_before_the_keys_are_used() -> void:
	var hall := open_hall_alone()
	press(hall, "FuseBoxButton")
	var first: Button = hall.find_child("Wire_" + Settings.WIRE_COLOURS[0], true, false)
	assert_true((first.get_theme_stylebox("normal") as StyleBoxFlat).border_color != HallScript.HIGHLIGHT, "no frame at first")
	key(hall, "ui_right")
	var second: Button = hall.find_child("Wire_" + Settings.WIRE_COLOURS[1], true, false)
	assert_eq((second.get_theme_stylebox("normal") as StyleBoxFlat).border_color, HallScript.HIGHLIGHT, "the keys show it")


# Playtest: the doll scared you both on her own and on the stairs; the stairs are enough.
# She is no button of her own (so also no dark box around her).
func test_only_the_dark_stairs_make_the_doll_turn() -> void:
	var hall := open_hall_alone()
	assert_true(hall.find_child("DollSpot", true, false) == null, "no click area on the doll")


func test_in_a_team_the_doll_has_no_note() -> void:
	var hall := open_hall()
	hall._close_mission()
	assert_eq(is_shown(hall, "DollNote"), false, "no note in her lap: it is only for single player")


# Spec 34: with "Reduce flashing" the hall stays steadily a little dark, no flicker.
func test_reduced_flashing_keeps_the_hall_steady() -> void:
	Comfort.reduce_flashing = true
	var hall := open_hall()
	var overlay: ColorRect = find(hall, "FlickerOverlay")
	var seen := {}
	for i in 40:
		hall._on_flicker_tick()
		seen[snappedf(overlay.color.a, 0.001)] = true
	assert_eq(seen.size(), 1, "one steady darkness: %s" % [seen.keys()])
	var a: float = seen.keys()[0]
	assert_true(a > 0.0 and a <= HallScript.flicker_strength(0) * 0.5 + 0.001, "a little dark: %s" % a)
	Comfort.reduce_flashing = false
