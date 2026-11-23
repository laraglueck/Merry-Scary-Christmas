# Tests for spec 32: the browser version has no emoji font, so emojis are left out there.
extends "res://tests/base_test.gd"

const WebText = preload("res://scripts/web_text.gd")


func test_on_the_laptop_the_text_stays_as_it_is() -> void:
	assert_eq(WebText.clean("🏆 Fastest escapes", false), "🏆 Fastest escapes", "unchanged")


func test_in_the_browser_emojis_are_left_out() -> void:
	assert_eq(WebText.clean("🏆 Fastest escapes", true), "Fastest escapes", "trophy gone")
	assert_eq(WebText.clean("✨ Ho ho hint", true), "Ho ho hint", "sparkles gone")
	assert_eq(WebText.clean("[b]🎄 Your mission[/b]\n\n⏰ 20 minutes", true), "[b]Your mission[/b]\n\n20 minutes", "mission")
	assert_eq(WebText.clean("➜ 1. Team", true), "> 1. Team", "the arrow becomes >")


func test_normal_letters_and_signs_stay_in_the_browser() -> void:
	var text := "•  Look — it's 3 °C… ä é – ×"
	assert_eq(WebText.clean(text, true), text, "nothing else changes")
