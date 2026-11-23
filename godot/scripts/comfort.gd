# Comfort settings for this device (spec 34), until the game is closed.
# Static, so every screen reads the same value without passing it around.
extends RefCounted

# On: no flickering light (hall, title window) and soft glows instead of bright flashes.
static var reduce_flashing := false


static func switch_text() -> String:
	return "Reduce flashing: %s" % ("On" if reduce_flashing else "Off")
