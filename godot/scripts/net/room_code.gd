# Room codes (spec 03b): 4 letters that tell the others which room to join,
# and the message the host sends on the Wi-Fi so others can find it.
# Pure functions: no network here.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const MESSAGE_TAG := "MSC1"  # "Merry Scary Christmas, version 1": ignore other programs' messages


static func make_code(rng: RandomNumberGenerator) -> String:
	var letters: String = Settings.ROOM_CODE_LETTERS
	var code := ""
	for i in Settings.ROOM_CODE_LENGTH:
		code += letters[rng.randi_range(0, letters.length() - 1)]
	return code


# " krtw " -> "KRTW"
static func normalize(text: String) -> String:
	return text.strip_edges().to_upper()


static func is_valid_code(text: String) -> bool:
	var code := normalize(text)
	if code.length() != Settings.ROOM_CODE_LENGTH:
		return false
	for letter in code:
		if letter not in Settings.ROOM_CODE_LETTERS:
			return false
	return true


# "KRTW", 47411 -> "MSC1|KRTW|47411"
static func announce_message(code: String, port: int) -> String:
	return "%s|%s|%d" % [MESSAGE_TAG, code, port]


# "MSC1|KRTW|47411" -> {"code": "KRTW", "port": 47411}; anything else -> {}
static func parse_announce(text: String) -> Dictionary:
	var parts := text.split("|")
	if parts.size() != 3 or parts[0] != MESSAGE_TAG:
		return {}
	if not is_valid_code(parts[1]) or not parts[2].is_valid_int():
		return {}
	return {"code": parts[1], "port": parts[2].to_int()}
