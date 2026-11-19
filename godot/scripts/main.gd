# Main scene (spec 04, 07, 11, 12): keeps the network connection and shows the right
# screen: on this device only, the loading screen with the story, then the title (until
# "Start"); the lobby before the game starts, then the character selection (spec 18), then
# the place where the team is (hall, a room, the attic). If the host leaves, everyone is back in the lobby.
# The music plays here, so it goes on from screen to screen until the game starts.
# The clock (spec 13) and the inventory bar (spec 14) are shown here too, on top of
# every screen while the game runs.
#
# TEAM: your room's scene = a new entry in SCREENS (key = its place, e.g. "bedroom").
# Until then the place shows PLACEHOLDER with its name and "Back to the hall".
extends Node

const NetworkScript = preload("res://scripts/net/network.gd")
const SCREENS := {
	"intro": preload("res://scenes/intro.tscn"),
	"title": preload("res://scenes/title.tscn"),
	"lobby": preload("res://scenes/lobby.tscn"),
	"select": preload("res://scenes/character_select.tscn"),  # choose your character (spec 18)
	"hall": preload("res://scenes/hall.tscn"),
	"living_room": preload("res://scenes/living_room.tscn"),  # Lara
	"bathroom": preload("res://scenes/bathroom.tscn"),
	"attic": preload("res://scenes/attic.tscn"),       # spec 16
	"merry": preload("res://scenes/ending.tscn"),      # the three ways a game ends (spec 16)
	"scary": preload("res://scenes/ending.tscn"),
	"midnight": preload("res://scenes/ending.tscn"),
}
const PLACEHOLDER = preload("res://scenes/placeholder_room.tscn")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const IMAGES := "res://assets/images/"
const Settings = preload("res://scripts/settings.gd")
const CLOCK_COLOUR := Color("f3e6cf")
const CLOCK_WARNING_COLOUR := Color("ff4b3a")  # the last minute

var net: Node
var screen: Node
var screen_name := ""
var intro_done := false  # story finished or skipped, or a game already started here
var title_done := false  # "Start" pressed, or a game already started on this device
var music: AudioStreamPlayer
var clock_label: Label
var inventory_bar: PanelContainer
var _item_pictures := {}  # item id -> its picture in the bar
var _item_names := {}     # item id -> its name under the picture


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	_start_music()
	_build_clock()
	_build_inventory()
	net.changed.connect(_update_screen)
	net.game_changed.connect(_update_screen)
	_update_screen()


# First the story, then before "Start" -> title; no game yet (or game over) -> lobby; in the house -> where
# the team is; later phases (e.g. an end screen) -> that phase.
func current_screen() -> String:
	if net.game.is_empty():
		if not intro_done:
			return "intro"
		return "lobby" if title_done else "title"
	var phase: String = net.game.get("phase", "hall")
	if phase == "hall":
		return net.game.get("location", "hall")
	return phase


func _on_intro_finished() -> void:
	intro_done = true
	_update_screen()


func _on_title_start_pressed() -> void:
	title_done = true
	_update_screen()


func _update_screen() -> void:
	_update_clock()
	_update_inventory()
	if not net.game.is_empty():
		intro_done = true  # once a game ran here, game over leads back to the lobby
		title_done = true
		if net.game.get("phase") != "select":
			music.stop()  # the music belongs to the screens before the game (the selection is one of them)
	var wanted := current_screen()
	if wanted == screen_name:
		return
	if screen != null:
		screen.queue_free()  # removed at the end of this frame
	screen = SCREENS.get(wanted, PLACEHOLDER).instantiate()
	screen.net = net
	if "place" in screen:
		screen.place = wanted
	if screen.has_signal("finished"):
		screen.finished.connect(_on_intro_finished)
	if screen.has_signal("start_pressed"):
		screen.start_pressed.connect(_on_title_start_pressed)
	add_child(screen)
	screen_name = wanted


# The menu music (loops): loading screen, title and lobby, without a break between them.
func _start_music() -> void:
	music = AudioStreamPlayer.new()
	music.name = "Music"
	var stream: AudioStreamMP3 = load("res://assets/sounds/music_lobby.mp3")
	stream.loop = true
	music.stream = stream
	# Not in the headless test run: no sound card there, and a sound still playing at
	# the end shows up as a leak warning.
	music.autoplay = DisplayServer.get_name() != "headless"
	add_child(music)


# "Midnight in 09:58" at the top centre, above every screen (its own canvas layer).
func _build_clock() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ClockLayer"
	layer.layer = 5
	add_child(layer)
	clock_label = Label.new()
	clock_label.name = "ClockLabel"
	clock_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_label.offset_left = -160
	clock_label.offset_right = 160
	clock_label.offset_top = 12
	clock_label.offset_bottom = 52
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_label.add_theme_font_size_override("font_size", 26)
	clock_label.add_theme_color_override("font_outline_color", Color.BLACK)
	clock_label.add_theme_constant_override("outline_size", 6)
	clock_label.visible = false
	layer.add_child(clock_label)


# Shown only while the game runs; red in the last minute.
func _update_clock() -> void:
	var running: bool = not net.game.is_empty() and net.game.get("phase") == "hall"
	clock_label.visible = running
	if running:
		var left := ClockRules.time_left(net.game)
		clock_label.text = "Midnight in " + ClockRules.as_text(left)
		var colour := CLOCK_WARNING_COLOUR if left < Settings.CLOCK_WARNING_SECONDS else CLOCK_COLOUR
		clock_label.add_theme_color_override("font_color", colour)


# Five slots at the bottom right, above every screen, in the order of Settings.ITEMS.
# Clicks go through it to the screen below.
func _build_inventory() -> void:
	inventory_bar = PanelContainer.new()
	inventory_bar.name = "InventoryBar"
	inventory_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	inventory_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # grows to the left and up
	inventory_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory_bar.offset_left = -16
	inventory_bar.offset_top = -16
	inventory_bar.offset_right = -16
	inventory_bar.offset_bottom = -16
	inventory_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_bar.add_theme_stylebox_override("panel", _hud_box(Color(0.08, 0.05, 0.05, 0.82), Color("8a6a3a"), 8))
	inventory_bar.visible = false
	get_node("ClockLayer").add_child(inventory_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_bar.add_child(row)
	for item in Settings.ITEMS:
		var slot := PanelContainer.new()
		slot.name = "InventorySlot_" + item["id"]
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", _hud_box(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.12), 4))
		row.add_child(slot)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(box)
		var holder := Control.new()  # keeps the slot's size while it is empty
		holder.custom_minimum_size = Vector2(56, 44)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(holder)
		var picture := TextureRect.new()
		picture.name = "InventoryPicture_" + item["id"]
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # first, then the size
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var file: String = IMAGES + item["picture"]
		if ResourceLoader.exists(file):  # the photo has no picture yet: name only
			picture.texture = load(file)
		picture.visible = false
		holder.add_child(picture)
		var name_label := Label.new()
		name_label.name = "InventoryName_" + item["id"]
		name_label.custom_minimum_size = Vector2(0, 16)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", CLOCK_COLOUR)
		box.add_child(name_label)
		_item_pictures[item["id"]] = picture
		_item_names[item["id"]] = name_label


# A found item shows its picture and name; an empty slot stays dark (no spoiler).
func _update_inventory() -> void:
	var running: bool = not net.game.is_empty() and net.game.get("phase") == "hall"
	inventory_bar.visible = running
	if not running:
		return
	for item in Settings.ITEMS:
		var found := InventoryRules.has(net.game, item["id"])
		_item_pictures[item["id"]].visible = found
		_item_names[item["id"]].text = item["name"] if found else ""


func _hud_box(fill: Color, border: Color, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(margin)
	return box

