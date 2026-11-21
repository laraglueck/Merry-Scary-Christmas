# Tests for spec 16: the end screen for Merry Christmas, Scary Christmas and Midnight.
extends "res://tests/base_test.gd"

const EndingScene = preload("res://scenes/ending.tscn")
const Settings = preload("res://scripts/settings.gd")


# Stands in for network.gd: only holds the finished game.
class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {}


# Opens the end screen like main.gd does: with the net and the phase as place.
func open_ending(phase: String, inventory: Array, seconds_used := 0) -> Node:
	var net := FakeNet.new()
	tree.root.add_child(net)
	net.game = {"phase": phase, "inventory": inventory, "seconds_played": seconds_used,
			"penalty_seconds": 0, "last_event": ""}
	var ending = EndingScene.instantiate()
	ending.net = net
	ending.place = phase
	tree.root.add_child(ending)
	return ending


func picture_of(ending: Node) -> String:
	return find(ending, "Background").texture.resource_path.get_file()


func test_merry_christmas_shows_its_title_and_picture() -> void:
	var ending := open_ending("merry", ["gift_1", "gift_2", "gift_3", "photo"])
	assert_eq(text_of(ending, "PlaceTitle"), "Merry Christmas!", "title")
	assert_eq(picture_of(ending), "ui_win_merry.webp", "picture")
	assert_contains(text_of(ending, "Line"), "remembered who he was", "line")


func test_scary_christmas_shows_its_title_and_picture() -> void:
	var ending := open_ending("scary", ["gift_1", "gift_2", "gift_3", "key"])
	assert_eq(text_of(ending, "PlaceTitle"), "Scary Christmas!", "title")
	assert_eq(picture_of(ending), "ui_win_scary.webp", "picture")
	assert_contains(text_of(ending, "Line"), "locked in", "line")


func test_midnight_shows_its_title_and_picture() -> void:
	var ending := open_ending("midnight", ["gift_2"], Settings.GAME_SECONDS)
	assert_eq(text_of(ending, "PlaceTitle"), "Midnight", "title")
	assert_eq(picture_of(ending), "ui_lose.webp", "picture")
	assert_contains(text_of(ending, "Line"), "struck twelve", "line")


func test_shows_the_presents_found() -> void:
	var ending := open_ending("scary", ["gift_1", "gift_3", "key"])
	assert_contains(text_of(ending, "Result"), "Presents found: 2 of 3", "presents")


func test_a_win_shows_the_time_left() -> void:
	var ending := open_ending("merry", ["photo"], Settings.GAME_SECONDS - 450)  # 450 s left = 07:30
	assert_contains(text_of(ending, "Result"), "07:30 before midnight", "time left")


func test_midnight_shows_no_time_left() -> void:
	var ending := open_ending("midnight", [], Settings.GAME_SECONDS)
	assert_true(not text_of(ending, "Result").contains("before midnight"), "no time line")


# ---------- sounds (spec 20) ----------

func test_each_ending_plays_its_sounds() -> void:
	assert_eq(open_ending("merry", []).sounds_played, ["music_merry.mp3"], "merry: only the soft Christmas music, no drum fanfare (spec 29)")
	assert_eq(open_ending("scary", []).sounds_played, ["music_scary.mp3"], "scary: only the broken music box, no drum fanfare (spec 29)")
	# Midnight: first the clock strikes and Jingles wakes; the lose music comes after (spec 21).
	assert_eq(open_ending("midnight", [], Settings.GAME_SECONDS).sounds_played, ["sfx_clock_chime.mp3"], "midnight")


# ---------- midnight: he wakes up (spec 21) ----------

func test_at_midnight_jingles_wakes_up_first() -> void:
	var ending := open_ending("midnight", [], Settings.GAME_SECONDS)
	var wake: Control = find(ending, "WakeUp")
	assert_true(wake != null and wake.visible, "the wake-up comes first")
	assert_eq(find(ending, "WakeUpJingles").texture.resource_path.get_file(), "char_jingles_awake.png", "wide awake")
	ending.show_ending()  # what happens after the strikes
	assert_eq(wake.visible, false, "then the end screen")
	assert_true("sfx_lose.mp3" in ending.sounds_played, "and the lose music")


func test_a_win_has_no_wake_up() -> void:
	var ending := open_ending("merry", [])
	assert_true(ending.find_child("WakeUp", true, false) == null, "no wake-up for a win")



# Spec 29: the Merry ending plays "Silent Night" as a music box (tools/make_music_merry.py).
func test_merry_music_is_a_real_song() -> void:
	var music: AudioStreamMP3 = load("res://assets/sounds/music_merry.mp3") if ResourceLoader.exists("res://assets/sounds/music_merry.mp3") else null
	assert_true(music != null, "music_merry.mp3 is there")
	assert_true(music != null and music.get_length() > 60.0, "a whole song, not a placeholder")


# Spec 29: gentle snow falls over the Merry picture, not over the other endings.
func test_snow_falls_only_at_the_merry_ending() -> void:
	var merry := open_ending("merry", [])
	var snow: CPUParticles2D = merry.find_child("MerrySnow", true, false)
	assert_true(snow != null and snow.emitting, "it snows at Merry Christmas")
	if snow != null:
		var words: Node = merry.find_child("PlaceTitle", true, false)
		assert_true(snow.get_index() < words.get_parent().get_index(), "behind the words")
	assert_true(open_ending("scary", []).find_child("MerrySnow", true, false) == null, "not at Scary Christmas")


# Spec 29: Scary Christmas plays "Silent Night" as a broken music box (tools/make_music_scary.py).
func test_scary_music_is_a_real_song() -> void:
	var music: AudioStreamMP3 = load("res://assets/sounds/music_scary.mp3") if ResourceLoader.exists("res://assets/sounds/music_scary.mp3") else null
	assert_true(music != null, "music_scary.mp3 is there")
	assert_true(music != null and music.get_length() > 40.0, "a whole song, not a placeholder")



# ---------- leaderboard and countdown (second test round) ----------

const TEST_BOARD := "user://test_leaderboard.json"


func use_test_board() -> void:
	OS.set_environment("MERRY_SCARY_LEADERBOARD", TEST_BOARD)
	if FileAccess.file_exists(TEST_BOARD):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_BOARD))


func open_won_ending(name: String, seconds_left: int) -> Node:
	var net := FakeNet.new()
	tree.root.add_child(net)
	net.game = {"phase": "merry", "inventory": [], "seconds_played": Settings.GAME_SECONDS - seconds_left,
			"penalty_seconds": 0, "last_event": "", "team_name": name}
	var ending = EndingScene.instantiate()
	ending.net = net
	ending.place = "merry"
	tree.root.add_child(ending)
	return ending


func test_a_win_goes_onto_the_leaderboard() -> void:
	use_test_board()
	open_won_ending("Team Rudolph", 300)
	var ending := open_won_ending("Team Comet", 450)
	assert_contains(text_of(ending, "LeaderboardTitle"), "Fastest", "a leaderboard")
	var list := text_of(ending, "LeaderboardRows")
	assert_contains(list, "Team Comet", "the new team")
	assert_true(list.find("Team Comet") < list.find("Team Rudolph"), "more time left comes first")
	assert_contains(list, "07:30", "with its time left")


func test_midnight_goes_not_onto_the_leaderboard() -> void:
	use_test_board()
	open_ending("midnight", [], Settings.GAME_SECONDS)
	var ending := open_won_ending("Team Comet", 450)
	assert_true(not text_of(ending, "LeaderboardRows").contains("Nameless"), "only the win is listed")


func test_the_end_screen_counts_down_to_christmas() -> void:
	use_test_board()
	var ending := open_won_ending("Team Comet", 450)
	assert_contains(text_of(ending, "Countdown"), "Christmas Eve", "the countdown")
