# Tests for spec 26: the real weather in Nuuk, read from Open-Meteo's answer (pure functions).
extends "res://tests/base_test.gd"

const WeatherRules = preload("res://scripts/rules/weather_rules.gd")


func answer(temperature: float, code: int) -> String:
	return JSON.stringify({"current": {"temperature_2m": temperature, "weather_code": code}})


func test_the_url_asks_for_nuuk() -> void:
	var url := WeatherRules.url()
	assert_true(url.begins_with("https://api.open-meteo.com/"), "Open-Meteo: " + url)
	assert_contains(url, "latitude=64.18", "Nuuk's latitude")
	assert_contains(url, "longitude=-51.69", "Nuuk's longitude")
	assert_contains(url, "current=temperature_2m,weather_code", "temperature and weather code")


func test_a_snowy_night_in_nuuk() -> void:
	var weather := WeatherRules.from_response(answer(-7.6, 73))
	assert_eq(weather.get("ok"), true, "a real answer")
	assert_eq(weather.get("kind"), "snow", "snow")
	assert_eq(weather.get("temperature"), -8, "rounded")
	assert_eq(weather.get("text"), "Nuuk, Greenland, tonight: -8 °C, snow.", "the line")


func test_weather_codes_become_kinds() -> void:
	var expected := {0: "clear", 1: "clear", 2: "cloudy", 3: "cloudy", 45: "fog", 48: "fog",
		51: "rain", 61: "rain", 67: "rain", 80: "rain", 71: "snow", 77: "snow", 85: "snow", 95: "storm", 99: "storm"}
	for code in expected:
		assert_eq(WeatherRules.from_response(answer(1.0, code)).get("kind"), expected[code], "code %d" % code)


func test_the_line_names_the_weather() -> void:
	assert_eq(WeatherRules.from_response(answer(2.4, 0)).get("text"), "Nuuk, Greenland, tonight: 2 °C, clear sky.", "clear")
	assert_eq(WeatherRules.from_response(answer(0.0, 61)).get("text"), "Nuuk, Greenland, tonight: 0 °C, rain.", "rain")
	assert_eq(WeatherRules.from_response(answer(-12.5, 95)).get("text"), "Nuuk, Greenland, tonight: -13 °C, a storm.", "storm")


func test_broken_answers_fall_back() -> void:
	var fallback := WeatherRules.fallback()
	assert_eq(fallback.get("ok"), false, "no real weather")
	assert_eq(fallback.get("kind"), "snow", "it snows anyway")
	assert_eq(fallback.get("text"), "The glass is too frosted to read the thermometer.", "the fallback line")
	for text in ["", "not json", "{}", "{\"current\": {}}", "{\"current\": {\"temperature_2m\": \"cold\", \"weather_code\": 3}}", "[1, 2]"]:
		assert_eq(WeatherRules.from_response(text), fallback, "fallback for: " + text)
