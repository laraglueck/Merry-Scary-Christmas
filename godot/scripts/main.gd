# Main scene (spec 04, 07, 11, 12, 23, 25): keeps the network connection and shows the right
# screen: on this device first the story (spec 12, until it ends or is skipped: spec 25),
# then the title (until "Start"), then the lobby; for the whole team the character selection (spec 18),
# then the place where the team is (hall, a room, the attic). If the host leaves, everyone is back in the lobby.
# The menu music plays here, on the title only (spec 23).
# While the game runs in the house, quiet house music plays instead (spec 22).
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
	"bedroom": preload("res://scenes/bedroom.tscn"),
	"attic": preload("res://scenes/attic.tscn"),       # spec 16
	"merry": preload("res://scenes/ending.tscn"),      # the three ways a game ends (spec 16)
	"scary": preload("res://scenes/ending.tscn"),
	"midnight": preload("res://scenes/ending.tscn"),
}
const PLACEHOLDER = preload("res://scenes/placeholder_room.tscn")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const PhotoRules = preload("res://scripts/rules/photo_rules.gd")
const PhotoPuzzle = preload("res://scenes/photo_puzzle.tscn")
const IMAGES := "res://assets/images/"
const Settings = preload("res://scripts/settings.gd")
const CLOCK_COLOUR := Color("f3e6cf")
const CLOCK_WARNING_COLOUR := Color("ff4b3a")  # the last minute

var net: Node
var screen: Node
var screen_name := ""
var title_done := false  # "Start" pressed, or a game already started on this device
var story_done := false  # the story ended or was skipped on this device (spec 25)
var music: AudioStreamPlayer
var menu_music_on := false   # spec 23: true while the menu music plays, only on the title (the tests read this)
var house_music: AudioStreamPlayer
var house_music_on := false  # spec 22: true while the house music plays (the tests read this)
var clock_label: Label
var pause_button: Button   # spec 26: next to the clock while the game runs
var pause_overlay: Control # spec 26: over every screen while the game is paused
var pause_label: Label
var inventory_bar: PanelContainer
var _item_pictures := {}  # item id -> its picture in the bar
var _item_names := {}     # item id -> its name under the picture
var _piece_pictures := {} # torn photo piece -> its small picture in the photo's slot (spec 21)


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	_start_music()
	_build_house_music()
	_build_clock()
	_build_inventory()
	_build_pause()
	net.changed.connect(_update_screen)
	net.game_changed.connect(_update_screen)
	_update_screen()


# First the story; then before "Start" -> title; no game yet (or game over) -> lobby; in the house -> where
# the team is; later phases (e.g. an end screen) -> that phase.
func current_screen() -> String:
	if net.game.is_empty():
		if not story_done:
			return "intro"
		return "lobby" if title_done else "title"
	var phase: String = net.game.get("phase", "hall")
	if phase == "hall":
		return net.game.get("location", "hall")
	return phase


# The story is over on this device (voice ended, click or key): on to the title (spec 25).
func _on_intro_finished() -> void:
	story_done = true
	_update_screen()


func _on_title_start_pressed() -> void:
	title_done = true
	_update_screen()


func _update_screen() -> void:
	_update_clock()
	_update_house_music()
	_update_inventory()
	_update_pause()
	if not net.game.is_empty():
		title_done = true
		story_done = true
	var wanted := current_screen()
	_set_menu_music(wanted == "title")
	if wanted == screen_name:
		return
	if screen != null:
		screen.queue_free()  # removed at the end of this frame
	screen = SCREENS.get(wanted, PLACEHOLDER).instantiate()
	screen.net = net
	if "place" in screen:
		screen.place = wanted
	if wanted == "intro":
		screen.lead_in = Settings.STORY_LEAD_IN_SECONDS  # fade in, then the voice (spec 23)
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
	music.volume_db = Settings.MENU_MUSIC_DB  # the trailer gets loud after its quiet start (spec 22)
	add_child(music)


# Spec 23: the menu music belongs to the title only.
func _set_menu_music(on: bool) -> void:
	if on == menu_music_on:
		return
	menu_music_on = on
	# Not in the headless test run: no sound card there, and a sound still playing at
	# the end shows up as a leak warning.
	if DisplayServer.get_name() == "headless":
		return
	if on:
		music.play()
	else:
		music.stop()


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
		if item["id"] in PhotoRules.PIECES:
			continue  # the torn pieces share the photo's slot (spec 21)
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
		if item["id"] == PhotoRules.WHOLE:
			_build_piece_pictures(slot, holder)
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


# The photo's slot also shows the torn pieces found so far, small and side by side, and
# a click on it opens the puzzle once all three are there (spec 21).
func _build_piece_pictures(slot: PanelContainer, holder: Control) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 1)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	for piece in PhotoRules.PIECES:
		var picture := TextureRect.new()
		picture.name = "InventoryPiece_" + piece
		picture.texture = load(IMAGES + "item_%s.png" % piece)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(18, 44)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.visible = false
		row.add_child(picture)
		_piece_pictures[piece] = picture
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_photo_slot_input)


func _on_photo_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		open_photo_puzzle()


# All three pieces found and the photo not whole yet: the puzzle opens over the game.
func open_photo_puzzle() -> void:
	if net.game.is_empty() or not PhotoRules.all_found(net.game) or get_node("ClockLayer").has_node("PhotoPuzzle"):
		return
	var puzzle := PhotoPuzzle.instantiate()
	puzzle.name = "PhotoPuzzle"
	puzzle.net = net
	get_node("ClockLayer").add_child(puzzle)


# A found item shows its picture and name; an empty slot stays dark (no spoiler).
func _update_inventory() -> void:
	var running: bool = not net.game.is_empty() and net.game.get("phase") == "hall"
	inventory_bar.visible = running
	if not running:
		return
	for item in Settings.ITEMS:
		if not _item_pictures.has(item["id"]):
			continue  # a torn piece: shown in the photo's slot
		var found := InventoryRules.has(net.game, item["id"])
		_item_pictures[item["id"]].visible = found
		_item_names[item["id"]].text = item["name"] if found else ""
	# The torn pieces in the photo's slot, until the photo is whole (spec 21).
	var pieces := 0
	for piece in PhotoRules.PIECES:
		var has_piece := InventoryRules.has(net.game, piece)
		_piece_pictures[piece].visible = has_piece
		if has_piece:
			pieces += 1
	if pieces > 0 and not InventoryRules.has(net.game, PhotoRules.WHOLE):
		_item_names[PhotoRules.WHOLE].text = "Pieces %d/3" % pieces


func _hud_box(fill: Color, border: Color, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(margin)
	return box


# Spec 22: quiet music in the house, under the rooms' own sounds.
func _build_house_music() -> void:
	house_music = AudioStreamPlayer.new()
	house_music.name = "HouseMusic"
	var stream: AudioStreamMP3 = load("res://assets/sounds/music_house.mp3")
	stream.loop = true
	house_music.stream = stream
	house_music.volume_db = Settings.HOUSE_MUSIC_DB
	add_child(house_music)


# On while the game runs in the house (every room), off before it and at the end.
func _update_house_music() -> void:
	var in_house: bool = not net.game.is_empty() and net.game.get("phase") == "hall"
	if in_house == house_music_on:
		return
	house_music_on = in_house
	if DisplayServer.get_name() == "headless":
		return  # the test run has no sound card
	if in_house:
		house_music.play()
	else:
		house_music.stop()


# ---------- pause (spec 26) ----------

# "Pause" right of the clock; while paused a dark layer over everything with "Continue".
func _build_pause() -> void:
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "Pause"
	pause_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pause_button.offset_left = 170
	pause_button.offset_right = 270
	pause_button.offset_top = 12
	pause_button.offset_bottom = 52
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.pressed.connect(func(): net.send_action("pause", {}))
	pause_button.visible = false
	get_node("ClockLayer").add_child(pause_button)

	var layer := CanvasLayer.new()  # above the clock, the inventory and the photo puzzle
	layer.name = "PauseLayer"
	layer.layer = 10
	add_child(layer)
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0, 0, 0, 0.7)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # no clicks on the game below
	pause_overlay.visible = false
	layer.add_child(pause_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -220
	box.offset_right = 220
	box.offset_top = -80
	box.offset_bottom = 80
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	pause_overlay.add_child(box)
	pause_label = Label.new()
	pause_label.name = "PauseLabel"
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 36)
	pause_label.add_theme_color_override("font_color", CLOCK_COLOUR)
	pause_label.add_theme_color_override("font_outline_color", Color.BLACK)
	pause_label.add_theme_constant_override("outline_size", 6)
	box.add_child(pause_label)
	var go_on := Button.new()
	go_on.name = "ContinueButton"
	go_on.text = "Continue"
	go_on.custom_minimum_size = Vector2(240, 58)
	go_on.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_on.add_theme_font_size_override("font_size", 28)
	go_on.pressed.connect(func(): net.send_action("resume", {}))
	box.add_child(go_on)


func _update_pause() -> void:
	var running: bool = not net.game.is_empty() and net.game.get("phase") == "hall"
	var paused: bool = running and net.game.get("paused", false)
	pause_button.visible = running and not paused
	pause_overlay.visible = paused
	if paused:
		pause_label.text = "Paused by Player %d" % (int(net.game.get("paused_by", 0)) + 1)
