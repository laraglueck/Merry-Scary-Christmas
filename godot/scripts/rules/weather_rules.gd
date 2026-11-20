# The real weather (spec 26): Open-Meteo's answer for Nuuk, read into one short line.
# Pure functions: the window view asks the service, these only read its answer.
# Anything broken becomes fallback(), so the game never stops because of the weather.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")

# How each kind of weather is said in the line ("..., tonight: -8 °C, snow.").
const WORDS := {"clear": "clear sky", "cloudy": "cloudy", "fog": "fog", "rain": "rain",
	"snow": "snow", "storm": "a storm"}
const FALLBACK_TEXT := "The glass is too frosted to read the thermometer."


static func url() -> String:
	return "https://api.open-meteo.com/v1/forecast?latitude=%.2f&longitude=%.2f&current=temperature_2m,weather_code" \
		% [Settings.WEATHER_LATITUDE, Settings.WEATHER_LONGITUDE]


# {"ok", "kind", "temperature", "text"} from the service's text, or fallback().
static func from_response(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:  # JSON.new().parse prints nothing; JSON.parse_string would
		return fallback()
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("current")) != TYPE_DICTIONARY:
		return fallback()
	var temperature = data["current"].get("temperature_2m")
	var code = data["current"].get("weather_code")
	if not _is_number(temperature) or not _is_number(code):
		return fallback()
	var kind := kind_for_code(int(code))
	var rounded := roundi(temperature)
	var line := "%s, tonight: %d °C, %s." % [Settings.WEATHER_PLACE, rounded, WORDS[kind]]
	return {"ok": true, "kind": kind, "temperature": rounded, "text": line}


static func fallback() -> Dictionary:
	return {"ok": false, "kind": "snow", "text": FALLBACK_TEXT}


# WMO weather codes (used by Open-Meteo) grouped into what the window can show.
static func kind_for_code(code: int) -> String:
	if code <= 1:
		return "clear"
	if code in [45, 48]:
		return "fog"
	if (code >= 51 and code <= 67) or (code >= 80 and code <= 82):
		return "rain"
	if (code >= 71 and code <= 77) or code in [85, 86]:
		return "snow"
	if code >= 95:
		return "storm"
	return "cloudy"


static func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
