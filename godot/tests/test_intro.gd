# Tests for spec 12: the loading screen tells the story with voice and subtitles.
extends "res://tests/base_test.gd"

const IntroScene = preload("res://scenes/intro.tscn")
const Intro = preload("res://scripts/intro.gd")


func open_intro() -> Node:
	var intro = IntroScene.instantiate()
	tree.root.add_child(intro)
	return intro


func test_intro_starts_with_the_first_line() -> void:
	var intro := open_intro()
	assert_eq(text_of(intro, "SubtitleLabel"), Intro.STORY_LINES[0], "first line")


func test_intro_shows_every_line_in_order() -> void:
	var intro := open_intro()
	var seen := []
	for i in 400:  # 40 seconds in steps of 0.1 s, longer than the voice
		intro.advance(0.1)
		var line := text_of(intro, "SubtitleLabel")
		if line != "" and (seen.is_empty() or seen[-1] != line):
			seen.append(line)
	assert_eq(seen, Intro.STORY_LINES, "all lines, in order")


func test_start_times_go_up_and_end_before_the_voice() -> void:
	var times: Array = Intro.LINE_START_SECONDS
	assert_eq(times.size(), Intro.STORY_LINES.size(), "one start time per line")
	for i in range(1, times.size()):
		assert_true(times[i] > times[i - 1], "line %d after line %d" % [i + 1, i])
	assert_eq(times[0], 0.0, "first line at the start")
	assert_true(times[-1] < 33.6, "last line starts before the voice ends")


func test_line_follows_the_recording() -> void:
	var intro := open_intro()
	intro.advance(9.5)
	assert_contains(text_of(intro, "SubtitleLabel"), "Then the storm came.", "third line at 0:09")
	intro.advance(6.0)
	assert_contains(text_of(intro, "SubtitleLabel"), "Santa Claus fired me", "fourth line at 0:15")


func test_voice_plays_once() -> void:
	var intro := open_intro()
	var voice: AudioStreamPlayer = find(intro, "Voice")
	assert_true(voice != null and voice.stream != null, "voice loaded")
	assert_true(voice != null and not voice.stream.loop, "voice once")


func test_click_skips() -> void:
	var intro := open_intro()
	var done := [0]
	intro.finished.connect(func(): done[0] += 1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	intro._gui_input(click)
	assert_eq(done[0], 1, "finished after a click")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	intro._unhandled_input(key)
	assert_eq(done[0], 1, "finished only once")


func press_key(intro: Node, keycode: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	intro._unhandled_input(key)


func test_volume_and_media_keys_do_not_skip() -> void:
	var intro := open_intro()
	var done := [false]
	intro.finished.connect(func(): done[0] = true)
	for keycode in [KEY_VOLUMEUP, KEY_VOLUMEDOWN, KEY_VOLUMEMUTE, KEY_MEDIAPLAY, KEY_SHIFT, KEY_META]:
		press_key(intro, keycode)
	assert_true(not done[0], "volume, media and modifier keys keep the story going")


func test_space_enter_and_escape_skip() -> void:
	for keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
		var intro := open_intro()
		var done := [false]
		intro.finished.connect(func(): done[0] = true)
		press_key(intro, keycode)
		assert_true(done[0], "%s skips" % OS.get_keycode_string(keycode))


func test_end_of_the_voice_finishes() -> void:
	var intro := open_intro()
	var done := [false]
	intro.finished.connect(func(): done[0] = true)
	find(intro, "Voice").finished.emit()
	assert_true(done[0], "finished when the voice ends")


func test_finishes_by_itself_even_without_sound() -> void:
	var intro := open_intro()
	var done := [false]
	intro.finished.connect(func(): done[0] = true)
	intro.advance(40.0)
	assert_true(done[0], "finished after the voice's length")
