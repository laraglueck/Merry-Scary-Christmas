# Tests for the leaderboard and the Christmas countdown (pure functions, no internet).
extends "res://tests/base_test.gd"

const Rules = preload("res://scripts/rules/leaderboard_rules.gd")
const Settings = preload("res://scripts/settings.gd")


func won_game(phase: String, name: String, seconds_played: int) -> Dictionary:
	return {"phase": phase, "team_name": name, "seconds_played": seconds_played, "penalty_seconds": 0}


func test_a_win_makes_an_entry() -> void:
	var entry := Rules.entry_for(won_game("merry", "Team Rudolph", Settings.GAME_SECONDS - 450))
	assert_eq(entry, {"name": "Team Rudolph", "ending": "merry", "seconds_left": 450, "mode": "team"}, "name, ending, time left, team")


func test_midnight_makes_no_entry() -> void:
	assert_eq(Rules.entry_for(won_game("midnight", "Team", Settings.GAME_SECONDS)), {}, "only wins count")


func test_a_game_without_a_name_gets_one() -> void:
	assert_eq(Rules.entry_for(won_game("scary", "  ", 100))["name"], "Nameless heroes", "never empty")


func test_the_fastest_come_first_and_only_ten() -> void:
	var entries := []
	for i in 12:
		entries.append({"name": "Team %d" % i, "ending": "merry", "seconds_left": i * 10})
	var top := Rules.top(entries)
	assert_eq(top.size(), 10, "ten at most")
	assert_eq(top[0]["name"], "Team 11", "most time left first")
	assert_eq(top[9]["name"], "Team 2", "then down")


func test_broken_or_strange_rows_are_left_out() -> void:
	var text := JSON.stringify([
		{"name": "Good", "ending": "merry", "seconds_left": 300},
		{"name": "", "ending": "merry", "seconds_left": 300},
		{"name": "Cheat", "ending": "merry", "seconds_left": 99999},
		{"name": "Odd", "ending": "dance", "seconds_left": 10},
		"not a row",
	])
	var rows := Rules.rows_from_text(text)
	assert_eq(rows.size(), 1, "only the good row")
	assert_eq(rows[0]["name"], "Good", "kept")
	assert_eq(Rules.rows_from_text("not json at all"), [], "broken answer: empty list")


func test_days_until_christmas_eve() -> void:
	assert_eq(Rules.days_until_christmas({"year": 2026, "month": 11, "day": 21}), 33, "from 21 November")
	assert_eq(Rules.days_until_christmas({"year": 2026, "month": 12, "day": 24}), 0, "on Christmas Eve")
	assert_eq(Rules.days_until_christmas({"year": 2026, "month": 12, "day": 26}), 363, "after it: next year's")


func test_countdown_text() -> void:
	assert_contains(Rules.countdown_text(33), "33 days", "days")
	assert_contains(Rules.countdown_text(1), "1 day ", "one day")
	assert_contains(Rules.countdown_text(0), "tonight", "Christmas Eve")


# ---------- solo and team lists (spec 34) ----------

func test_a_solo_win_is_marked_solo() -> void:
	var entry := Rules.entry_for(won_game("scary", "Alone", Settings.GAME_SECONDS - 100), true)
	assert_eq(entry["mode"], "solo", "played alone")


func test_rows_without_a_mode_are_team_and_strange_modes_are_left_out() -> void:
	var rows := Rules.rows_from_text(JSON.stringify([
		{"name": "Old", "ending": "merry", "seconds_left": 300},
		{"name": "Solo", "ending": "merry", "seconds_left": 200, "mode": "solo"},
		{"name": "Odd", "ending": "merry", "seconds_left": 100, "mode": "duo"},
	]))
	assert_eq(rows.size(), 2, "the strange mode is left out")
	assert_eq(rows[0]["mode"], "team", "saved before spec 34: a team win")
	assert_eq(rows[1]["mode"], "solo", "kept")


func test_each_mode_has_its_own_top_ten() -> void:
	var rows := []
	for i in 12:
		rows.append({"name": "Team %d" % i, "ending": "merry", "seconds_left": 500 + i, "mode": "team"})
	rows.append({"name": "Alone", "ending": "merry", "seconds_left": 10, "mode": "solo"})
	var solo := Rules.top(rows, "solo")
	assert_eq(solo.size(), 1, "only the solo win")
	assert_eq(solo[0]["name"], "Alone", "even with little time left")
	var team := Rules.top(rows, "team")
	assert_eq(team.size(), 10, "ten teams")
	assert_true(team.all(func(r): return r["mode"] == "team"), "no solo win in the team list")
