# Tests for spec 19: walking with WASD (pure functions + the host's game).
extends "res://tests/base_test.gd"

const WalkRules = preload("res://scripts/rules/walk_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return GameRules.new_game(rng)


func test_a_new_game_has_three_figures_standing_still() -> void:
	var figures: Dictionary = new_game()["figures"]
	assert_eq(figures.keys(), [0, 1, 2], "one per player")
	for player in figures:
		assert_eq(Vector2(figures[player]["dx"], figures[player]["dy"]), Vector2.ZERO, "standing still")
	assert_true(figures[0]["x"] < figures[1]["x"] and figures[1]["x"] < figures[2]["x"], "side by side, Player 1 left")


func test_set_direction_is_kept() -> void:
	var game := new_game()
	assert_eq(WalkRules.set_direction(game, 1, 1.0, 0.0), "", "allowed")
	assert_eq(Vector2(game["figures"][1]["dx"], game["figures"][1]["dy"]), Vector2(1, 0), "walking right")
	assert_eq(game["figures"][0]["dx"], 0.0, "the others stay")


func test_diagonal_is_not_faster() -> void:
	var game := new_game()
	WalkRules.set_direction(game, 0, 1.0, -1.0)
	var length := Vector2(game["figures"][0]["dx"], game["figures"][0]["dy"]).length()
	assert_eq(is_equal_approx(length, 1.0), true, "length 1: %s" % length)


func test_unknown_player_or_wild_values_change_nothing() -> void:
	var game := new_game()
	var before: Dictionary = game["figures"].duplicate(true)
	assert_contains(WalkRules.set_direction(game, 5, 1.0, 0.0), "unknown player", "refused")
	WalkRules.set_direction(game, 0, 50.0, 0.0)
	assert_eq(game["figures"][0]["dx"], 1.0, "never more than full speed")
	game["figures"] = before
	assert_eq(game["figures"], before, "nothing else changed")


func test_advance_walks_with_a_fixed_speed() -> void:
	var game := new_game()
	var start: float = game["figures"][0]["x"]
	WalkRules.set_direction(game, 0, 1.0, 0.0)
	assert_eq(WalkRules.advance(game, 0.1), true, "someone moved")
	assert_eq(is_equal_approx(game["figures"][0]["x"], start + Settings.WALK_SPEED * 0.1), true, "speed %s" % game["figures"][0]["x"])
	assert_eq(game["figures"][1]["x"], Settings.FIGURE_START_X[1], "the others stand")
	WalkRules.set_direction(game, 0, 0.0, 0.0)
	assert_eq(WalkRules.advance(game, 0.1), false, "nobody moves when nobody pushes a key")


func test_walking_up_goes_into_the_room() -> void:
	var game := new_game()
	var start: float = game["figures"][1]["y"]
	WalkRules.set_direction(game, 1, 0.0, -1.0)  # W
	WalkRules.advance(game, 0.2)
	assert_true(game["figures"][1]["y"] < start, "further back = smaller y")
	WalkRules.set_direction(game, 1, 0.0, 1.0)  # S
	WalkRules.advance(game, 0.4)
	assert_true(game["figures"][1]["y"] > start, "and forward again")


func test_everybody_starts_on_the_floor() -> void:
	for player in 3:
		var figure: Dictionary = new_game()["figures"][player]
		assert_true(WalkRules.is_on_floor("hall", Vector2(figure["x"], figure["y"])), "Player %d starts on the floor" % (player + 1))


func test_walls_and_stairs_are_not_floor() -> void:
	assert_eq(WalkRules.is_on_floor("hall", Vector2(20, 300)), false, "left wall")
	assert_eq(WalkRules.is_on_floor("hall", Vector2(1300, 600)), false, "right wall, far back")
	assert_eq(WalkRules.is_on_floor("hall", Vector2(200, 560)), false, "the left wall slopes: not so far back at the side")
	assert_eq(WalkRules.is_on_floor("hall", Vector2(850, 540)), false, "the stairs")
	assert_eq(WalkRules.is_on_floor("hall", Vector2(690, 650)), true, "the middle of the floor")
	assert_eq(WalkRules.is_on_floor("hall", Vector2(60, 765)), true, "front left corner")


func test_the_figure_never_walks_into_the_wall() -> void:
	var game := new_game()
	for direction in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		WalkRules.set_direction(game, 0, direction.x, direction.y)
		for step in 400:
			WalkRules.advance(game, 0.05)
			var feet := Vector2(game["figures"][0]["x"], game["figures"][0]["y"])
			assert_true(WalkRules.is_on_floor("hall", feet), "still on the floor going %s: %s" % [direction, feet])
			if not WalkRules.is_on_floor("hall", feet):
				return


func test_walking_into_the_left_wall_slides_along_it() -> void:
	var game := new_game()
	game["figures"][0]["x"] = 330.0
	game["figures"][0]["y"] = 640.0
	WalkRules.set_direction(game, 0, -1.0, -1.0)  # into the left wall, and back
	var start_x: float = game["figures"][0]["x"]
	var start_y: float = game["figures"][0]["y"]
	WalkRules.advance(game, 3.0)
	var feet := Vector2(game["figures"][0]["x"], game["figures"][0]["y"])
	assert_true(WalkRules.is_on_floor("hall", feet), "on the floor")
	assert_true(feet.distance_to(Vector2(start_x, start_y)) > 20.0, "it slid along the wall, not stuck: %s" % feet)


func test_walking_straight_into_a_wall_stops() -> void:
	var game := new_game()
	game["figures"][0]["x"] = 1000.0
	game["figures"][0]["y"] = 700.0
	WalkRules.set_direction(game, 0, 1.0, 0.0)
	WalkRules.advance(game, 10.0)
	assert_true(game["figures"][0]["x"] > 1000.0, "it walked")
	assert_true(WalkRules.is_on_floor("hall", Vector2(game["figures"][0]["x"], game["figures"][0]["y"])), "and stopped at the wall")
	assert_eq(WalkRules.advance(game, 0.1), false, "no more movement at the wall")


func test_far_away_figures_are_drawn_smaller() -> void:
	var limits := WalkRules.depth_range("hall")
	assert_true(WalkRules.depth_scale("hall", limits["top"]) < WalkRules.depth_scale("hall", limits["bottom"]), "perspective")
	assert_eq(WalkRules.depth_scale("hall", limits["bottom"]), 1.0, "full size in front")
	assert_eq(WalkRules.depth_scale("hall", limits["top"]), Settings.FAR_SCALE, "smallest at the far edge")


func test_move_is_a_game_action() -> void:
	var game := new_game()
	GameRules.apply(game, 1, "move", {"dx": 1.0, "dy": 0.0})
	assert_eq(game["figures"][1]["dx"], 1.0, "Player 2 walks")
	GameRules.apply(game, 1, "move", {"dx": "far", "dy": 0.0})
	assert_eq(game["figures"][1]["dx"], 1.0, "a wrong value changes nothing")


func test_nobody_walks_after_the_end() -> void:
	var game := new_game()
	game["phase"] = "midnight"
	GameRules.apply(game, 0, "move", {"dx": 1.0, "dy": 0.0})
	assert_eq(game["figures"][0]["dx"], 0.0, "the game is over")


# ---------- the host walks everybody and tells them (network) ----------

func test_the_host_moves_the_figures_and_everyone_sees_it() -> void:
	var room: Array = await make_started_room(47621)
	var start: float = room[0].game["figures"][1]["x"]
	room[1].send_action("move", {"dx": 1.0, "dy": 0.0})
	await wait_until(func(): return room[0].game["figures"][1]["dx"] == 1.0)
	room[0].advance_figures(0.5)
	assert_true(room[0].game["figures"][1]["x"] > start, "the host moved it")
	var seen := func(): return room.all(func(net): return net.game["figures"][1]["x"] > start)
	assert_true(await wait_until(seen), "everybody gets the new place")


func test_figures_are_sent_about_ten_times_a_second_and_when_they_stop() -> void:
	var room: Array = await make_started_room(47622)
	var start: float = room[0].game["figures"][0]["x"]
	room[0].send_action("move", {"dx": 1.0, "dy": 0.0})
	await wait_frames(3)
	room[0].advance_figures(0.02)
	await wait_frames(3)
	assert_true(room[2].game["figures"][0]["x"] == start, "too early: not sent yet")
	room[0].advance_figures(0.2)
	var moving := func(): return room[2].game["figures"][0]["x"] > start
	assert_true(await wait_until(moving), "sent after 0.1 s")
	room[0].send_action("move", {"dx": 0.0, "dy": 0.0})
	room[0].advance_figures(0.01)
	var final_x: float = room[0].game["figures"][0]["x"]
	var stopped := func(): return room[2].game["figures"][0]["x"] == final_x
	assert_true(await wait_until(stopped), "the last place is always sent")
