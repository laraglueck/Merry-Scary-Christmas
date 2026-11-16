# Tests for spec 02: the hall scene. They click buttons like a player would.
# Seed 42 gives: legend star = white, bell = blue, tree = black, snowflake = yellow
#   red fuse   (Player 1): white, blue, yellow, black  label: star, bell, snowflake, tree
#   green fuse (Player 2): blue, black, yellow, white  label: bell, tree, snowflake, star
#   gold fuse  (Player 3): blue, yellow, white, black  label: bell, snowflake, star, tree
extends "res://tests/base_test.gd"

const HallScene = preload("res://scenes/hall.tscn")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")

const RED_RIGHT := ["white", "blue", "yellow", "black"]
const GREEN_RIGHT := ["blue", "black", "yellow", "white"]
const GOLD_RIGHT := ["blue", "yellow", "white", "black"]
const RED_WRONG := ["blue", "white", "yellow", "black"]


# Opens the hall like starting the scene (this runs _ready).
func open_hall() -> Node:
	var hall = HallScene.instantiate()
	hall.seed_value = 42
	tree.root.add_child(hall)
	return hall


func click_wires(hall: Node, colours: Array) -> void:
	for colour in colours:
		press(hall, "Wire_" + colour)


# ---------- house plan ----------

func test_house_plan_shows_legend() -> void:
	var legend := text_of(open_hall(), "LegendLabel")
	for pair in ["star = white", "bell = blue", "tree = black", "snowflake = yellow"]:
		assert_contains(legend, pair, "legend")


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
	assert_contains(hint, "gold", "label of which fuse")
	assert_contains(hint, "bell, snowflake, star, tree", "label symbols")


func test_player_2_has_green_fuse_and_sees_red_label() -> void:
	var hall := open_hall()
	press(hall, "FuseBoxButton")
	press(hall, "PlayerButton1")
	assert_contains(text_of(hall, "FuseTitle"), "green", "own fuse")
	var hint := text_of(hall, "LabelHint")
	assert_contains(hint, "red", "label of which fuse")
	assert_contains(hint, "star, bell, snowflake, tree", "label symbols")


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
	for node_name in ["PenaltyLabel", "FusePanel", "RoomLamp2", "Message"]:
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
		var red_label := ", ".join(FuseRules.label_for(a.game["puzzle"], 0))
		assert_contains(text_of(hall, "LabelHint"), "red fuse", "sees the red fuse's label")
		assert_contains(text_of(hall, "LabelHint"), red_label, "label symbols")


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
