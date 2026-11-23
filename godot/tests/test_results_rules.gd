# Tests for spec 34: the results card on the end screen.
extends "res://tests/base_test.gd"

const ResultsRules = preload("res://scripts/rules/results_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const EndingScene = preload("res://scenes/ending.tscn")
const Settings = preload("res://scripts/settings.gd")


class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {}
	var my_index := 0


func test_the_inventory_remembers_who_found_an_item() -> void:
	var game := {"inventory": []}
	InventoryRules.add(game, "gift_2", 1)
	assert_eq(game["found_by"], {"gift_2": 1}, "Player 2 found present 2")
	InventoryRules.add(game, "gift_1")
	assert_true(not game["found_by"].has("gift_1"), "without a player nobody is named")


func test_a_wrong_try_is_counted_as_a_mistake() -> void:
	var game: Dictionary = GameRules.new_game(RandomNumberGenerator.new())
	var before: int = game.get("mistakes", 0)
	# A wrong fuse order: the fuse is solved by its own player only after the right order.
	var fuse: Dictionary = game["puzzle"]["fuses"][0]
	var wrong: Array = fuse["order"].duplicate()
	wrong.reverse()
	GameRules.apply(game, 0, "try_fuse", {"wires": wrong})
	if game["penalty_seconds"] > 0:
		assert_eq(game["mistakes"], before + 1, "one mistake")
		assert_eq(game["mistake_seconds"], Settings.FUSE_PENALTY_SECONDS, "its seconds")
	else:
		failures.append("the wrong fuse order cost no time: test setup is wrong")


func test_the_lines_for_a_whole_game() -> void:
	var game := {"seconds_played": 900, "penalty_seconds": 48, "mistakes": 3, "mistake_seconds": 60,
			"inventory": ["gift_1", "gift_2", "photo"], "found_by": {"gift_1": 0, "gift_2": 2, "photo": 1},
			"powers_used": [1], "characters": {1: {"character": "snowman"}}}
	var lines: Array = ResultsRules.lines(game)
	var text := "\n".join(lines)
	assert_contains(text, "Time left: 04:12", "the time left")
	assert_contains(text, "Mistakes: 3 (-60 s)", "the mistakes")
	assert_contains(text, "Powers: Freeze (Player 2)", "the power")
	assert_contains(text, "Present 1: Player 1", "who found present 1")
	assert_contains(text, "Present 2: Player 3", "who found present 2")
	assert_contains(text, "Photo: Player 2", "who put the photo together")


func test_the_lines_when_nothing_happened() -> void:
	var game := {"seconds_played": Settings.GAME_SECONDS, "penalty_seconds": 0, "inventory": []}
	var text := "\n".join(ResultsRules.lines(game))
	assert_contains(text, "Time left: 00:00", "midnight")
	assert_contains(text, "Mistakes: none", "no mistakes")
	assert_contains(text, "Powers: none", "no powers")
	assert_contains(text, "Nothing found", "nothing found")


func test_an_old_game_without_the_new_fields() -> void:
	var game := {"seconds_played": 100, "penalty_seconds": 20, "inventory": ["gift_3"]}
	var text := "\n".join(ResultsRules.lines(game))
	assert_contains(text, "Present 3: the team", "unknown finder")


func test_the_card_on_every_end_screen() -> void:
	for phase in ["merry", "scary", "midnight"]:
		var net := FakeNet.new()
		tree.root.add_child(net)
		net.game = {"phase": phase, "inventory": ["gift_1"], "found_by": {"gift_1": 0},
				"seconds_played": 600, "penalty_seconds": 0, "last_event": ""}
		var ending = EndingScene.instantiate()
		ending.net = net
		ending.place = phase
		tree.root.add_child(ending)
		await wait_frames(2)
		var card: Control = find(ending, "ResultsCard")
		assert_true(card != null and card.is_visible_in_tree(), phase + ": the card is there")
		assert_contains(text_of(ending, "ResultsRows"), "Present 1: Player 1", phase + ": who found what")
		var board: Control = find(ending, "LeaderboardPanel")
		if card != null and board != null:
			assert_true(not card.get_global_rect().intersects(board.get_global_rect()), phase + ": not over the leaderboard")
		ending.queue_free()
		net.queue_free()
		await wait_frames(1)
