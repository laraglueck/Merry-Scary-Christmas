# Texts for the browser version (spec 32). The browser has no emoji font, so an emoji would
# show as an empty box: there it is left out (and the arrow on the leaderboard becomes ">").
# On the laptop the text stays exactly as it is.
extends RefCounted

const ARROW := "➜"


static func clean(text: String, on_web := OS.has_feature("web")) -> String:
	if not on_web:
		return text
	text = text.replace(ARROW, ">")
	var emoji := RegEx.create_from_string("[\\x{1F000}-\\x{1FFFF}\\x{2600}-\\x{27BF}\\x{2300}-\\x{23FF}\\x{2B00}-\\x{2BFF}\\x{FE0F}] ?")
	return emoji.sub(text, "", true)
