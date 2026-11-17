# Tests for spec 11: the title screen with picture, music, voice and a Start button.
extends "res://tests/base_test.gd"

const TitleScene = preload("res://scenes/title.tscn")


func open_title() -> Node:
	var title = TitleScene.instantiate()
	tree.root.add_child(title)
	return title


func test_title_shows_name_picture_and_start() -> void:
	var title := open_title()
	assert_contains(text_of(title, "TitleLabel"), "Merry Scary Christmas", "game name")
	var picture: TextureRect = find(title, "Background")
	assert_true(picture != null and picture.texture != null, "title picture")
	assert_eq(is_disabled(title, "StartButton"), false, "start enabled")


func test_title_plays_looping_music_and_the_voice_once() -> void:
	var title := open_title()
	var music: AudioStreamPlayer = find(title, "Music")
	var voice: AudioStreamPlayer = find(title, "Voice")
	assert_true(music != null and music.stream != null, "music loaded")
	assert_true(music != null and music.stream.loop, "music loops")
	assert_true(voice != null and voice.stream != null, "voice loaded")
	assert_true(voice != null and not voice.stream.loop, "voice once")
	# Starting by itself (autoplay) is switched off in this headless run; check it by hand.


func test_start_button_sends_start_pressed() -> void:
	var title := open_title()
	var pressed := [false]
	title.start_pressed.connect(func(): pressed[0] = true)
	press(title, "StartButton")
	assert_true(pressed[0], "start_pressed sent")


func test_title_shows_the_three_figures() -> void:
	var title := open_title()
	for figure in ["Santa", "Snowman", "Nutcracker"]:
		var picture: TextureRect = find(title, figure)
		assert_true(picture != null and picture.texture != null, figure + " shown")


func test_window_light_flickers() -> void:
	var title := open_title()
	var dark: ColorRect = find(title, "WindowDark")
	assert_true(dark != null, "window overlay")
	if dark == null:
		return
	var seen := {}
	for i in 40:  # a whole flicker cycle, step by step
		title.flicker_step()
		seen[snappedf(dark.color.a, 0.01)] = true
	assert_true(seen.size() > 1, "the window goes dark and light again")
