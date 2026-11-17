# The end screen (spec 16): one screen for the three ways a game ends.
# main.gd shows it when the phase is "merry", "scary" or "midnight" and hands in
# that phase as `place`. Offline (Cmd R) it shows `place` with an empty game.
extends Control

const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")

const IMAGES := "res://assets/images/"
const GIFTS := ["gift_1", "gift_2", "gift_3"]
const ENDINGS := {
	"merry": {"picture": "ui_win_merry.webp", "title": "Merry Christmas!", "colour": Color("ffd76a"),
			"line": "Scary Jingles remembered who he was."},
	"scary": {"picture": "ui_win_scary.webp", "title": "Scary Christmas!", "colour": Color("e05a4a"),
			"line": "Scary Jingles is locked in. The presents are safe."},
	"midnight": {"picture": "ui_lose.webp", "title": "Midnight", "colour": Color("a9c4e8"),
			"line": "The clock struck twelve. Scary Jingles has won."},
}

@export var place := "merry"  # set by main.gd: the phase that ended the game
var net: Node = null          # set by main.gd


func _ready() -> void:
	var game: Dictionary = net.game if net != null and not net.game.is_empty() else {"phase": place}
	var ending: Dictionary = ENDINGS.get(place, ENDINGS["midnight"])
	_build_ui(ending, _result_text(game), str(game.get("last_event", "")))


# "Presents found: 2 of 3", and for a win the time that was left.
func _result_text(game: Dictionary) -> String:
	var found := 0
	for gift in GIFTS:
		if InventoryRules.has(game, gift):
			found += 1
	var text := "Presents found: %d of %d" % [found, GIFTS.size()]
	if place != "midnight" and game.has("seconds_played"):
		text += "   ·   %s before midnight" % ClockRules.as_text(ClockRules.time_left(game))
	return text


func _build_ui(ending: Dictionary, result: String, last_event: String) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("120b0c")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(IMAGES + ending["picture"])
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	# A dark band at the bottom, so the words stay readable on any picture.
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.6)
	band.position = Vector2(0, 470)
	band.size = Vector2(1152, 178)
	add_child(band)

	var words := VBoxContainer.new()
	words.position = Vector2(0, 482)
	words.size = Vector2(1152, 160)
	words.add_theme_constant_override("separation", 6)
	add_child(words)
	var title := _label(words, "PlaceTitle", ending["title"], 56)
	title.add_theme_color_override("font_color", ending["colour"])
	_label(words, "Line", ending["line"], 24)
	var result_label := _label(words, "Result", result, 20)
	result_label.add_theme_color_override("font_color", Color("d8c8ae"))

	# What happened last, e.g. "Player 2 took the key and locked Scary Jingles in."
	var message := _label(self, "Message", last_event, 18)
	message.position = Vector2(0, 16)
	message.size = Vector2(1152, 30)
	message.add_theme_color_override("font_color", Color("ffd76a"))

	# "Back to the lobby" needs a small network function (host clears the finished
	# game for everyone, Mathies). Until then the button exists but stays hidden.
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back to the lobby"
	back.visible = false
	back.position = Vector2(960, 590)
	add_child(back)


func _label(parent: Node, node_name: String, text: String, size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
