# Placeholder for a room that is not built yet (spec 07): its name and a way back.
# Owners: add your scene to SCREENS in main.gd, then this one is no longer used for it.
extends Control

const HouseRules = preload("res://scripts/rules/house_rules.gd")

var net: Node = null  # set by main.gd
var place := ""        # set by main.gd, e.g. "living_room"

var _message: Label


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("1b1012")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	var title := Label.new()
	title.name = "PlaceTitle"
	title.text = HouseRules.place_name(place)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	box.add_child(title)

	var note := Label.new()
	note.text = "This room is still being built by the team."
	note.add_theme_font_size_override("font_size", 20)
	box.add_child(note)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back to the hall"
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(_on_back_pressed)
	box.add_child(back)

	_message = Label.new()
	_message.name = "Message"
	_message.add_theme_color_override("font_color", Color("ffd76a"))
	box.add_child(_message)
	if net != null and not net.game.is_empty():
		_message.text = net.game.get("last_event", "")


func _on_back_pressed() -> void:
	if net != null:
		net.send_action("go_to", {"place": "hall"})
