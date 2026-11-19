# Tests for spec 04: the shared game Dictionary and its actions (pure functions).
extends "res://tests/base_test.gd"

const GameRules = preload("res://scripts/rules/game_rules.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")


func new_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return GameRules.new_game(rng)


func right_order(game: Dictionary, player: int) -> Array:
	return game["puzzle"]["fuses"][player]["order"].duplicate()


func wrong_order(game: Dictionary, player: int) -> Array:
	var order := right_order(game, player)
	order.reverse()  # 4 different colours: reversed is never the same order
	return order


func test_new_game_starts_in_the_hall() -> void:
	var game := new_game()
	assert_eq(game.get("phase"), "hall", "phase")
	assert_eq(game.get("penalty_seconds"), 0, "penalty")
	assert_eq(game.get("last_event"), "", "event")
	assert_eq(game.get("puzzle", {}).get("fuses", []).size(), 3, "3 fuses")


func test_right_wires_turn_on_the_players_own_fuse() -> void:
	var game := new_game()
	GameRules.apply(game, 1, "try_fuse", {"wires": right_order(game, 1)})
	assert_eq(game["puzzle"]["fuses"][1]["solved"], true, "green fuse on")
	assert_eq(game["puzzle"]["fuses"][0]["solved"], false, "red fuse untouched")
	assert_eq(game["last_event"], "Player 2 turned on the green fuse. The bathroom is lit!", "event")


func test_wrong_wires_cost_10_seconds_each_time() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "try_fuse", {"wires": wrong_order(game, 0)})
	assert_eq(game["penalty_seconds"], 10, "after 1 wrong try")
	assert_eq(game["last_event"], "Player 1: wrong order, -10 s", "event")
	GameRules.apply(game, 0, "try_fuse", {"wires": wrong_order(game, 0)})
	assert_eq(game["penalty_seconds"], 20, "after 2 wrong tries")


func test_invalid_wires_give_the_reason_without_penalty() -> void:
	var game := new_game()
	var puzzle_before: Dictionary = game["puzzle"].duplicate(true)
	GameRules.apply(game, 2, "try_fuse", {"wires": ["blue", "white"]})
	assert_eq(game["penalty_seconds"], 0, "no penalty")
	assert_contains(game["last_event"], "Player 3", "who")
	assert_contains(game["last_event"], "expected 4 wires", "reason")
	assert_eq(game["puzzle"], puzzle_before, "puzzle unchanged")


func test_missing_wires_are_invalid_not_a_crash() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "try_fuse", {})
	assert_contains(game.get("last_event", ""), "expected 4 wires", "reason")


func test_unknown_action_changes_nothing() -> void:
	var game := new_game()
	var before := game.duplicate(true)
	GameRules.apply(game, 0, "open_portal", {})
	assert_eq(game, before, "unchanged")


# ---------- walking (spec 07) ----------

func test_go_to_action_moves_the_team_and_names_the_player() -> void:
	var game := new_game()
	GameRules.apply(game, 1, "try_fuse", {"wires": right_order(game, 1)})
	GameRules.apply(game, 1, "go_to", {"place": "bathroom"})
	assert_eq(game.get("location"), "bathroom", "location")
	assert_eq(game["last_event"], "Player 2 opened the bathroom door.", "event")


func test_refused_go_to_shows_the_reason_and_changes_nothing() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "go_to", {"place": "bedroom"})
	assert_eq(game.get("location"), "hall", "still in the hall")
	assert_contains(game["last_event"], "Player 1", "who")
	assert_contains(game["last_event"], "still dark", "reason")
	assert_eq(game["penalty_seconds"], 0, "no penalty for walking")


# ---------- character selection (spec 18) ----------

func test_selection_actions_pick_and_ready() -> void:
	var game := {"phase": "select", "selection": {}, "last_event": ""}
	GameRules.apply(game, 1, "pick_character", {"character": "snowman", "colour": "green"})
	assert_eq(game["selection"][1], {"character": "snowman", "colour": "green", "accessory": "none", "ready": false}, "Player 2 picked")
	GameRules.apply(game, 1, "ready", {})
	assert_eq(game["selection"][1]["ready"], true, "Player 2 is ready")


func test_a_refused_selection_action_explains_why() -> void:
	var game := {"phase": "select", "selection": {}, "last_event": ""}
	GameRules.apply(game, 0, "pick_character", {"character": "santa", "colour": "red"})
	GameRules.apply(game, 1, "pick_character", {"character": "santa", "colour": "green"})
	assert_eq(game["selection"].has(1), false, "refused")
	assert_contains(game["last_event"], "Player 2", "names the player")
	assert_contains(game["last_event"], "taken by Player 1", "says why")


func test_selection_actions_do_nothing_in_a_running_game() -> void:
	var game := new_game()
	GameRules.apply(game, 0, "pick_character", {"character": "santa", "colour": "red"})
	assert_eq(game.has("selection"), false, "the running game has no selection")


func test_new_game_keeps_the_chosen_characters() -> void:
	var rng := RandomNumberGenerator.new()
	var chosen := {0: {"character": "santa", "colour": "red"}}
	assert_eq(GameRules.new_game(rng, chosen)["characters"], chosen, "stored")
	assert_eq(GameRules.new_game(rng)["characters"], {}, "empty by default")

