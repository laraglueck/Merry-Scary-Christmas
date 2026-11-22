# The hall (specs 02, 05, 07, 08, 08b): Gloria's picture with clickable spots for the fuse
# box, the three doors, the attic stairs and the house plan, plus close-ups of the fuse box
# and the house plan. Keys: left/right choose a spot (or a cable), Enter uses it, Esc goes back.
# In the fuse box, the cables are clicked in order (spec 02; dragging was taken back, spec 08b).
# Offline (no net, spec 02): one screen, the player buttons switch whose view we see.
# Online (main.gd hands in a net with a game, spec 04): this device shows only
# its own player; clicks go to the host, and the shared game comes back.
# The rules live in fuse_rules.gd and house_rules.gd. This script only shows them.
extends Control

const ButtonStyle = preload("res://scripts/button_style.gd")
const Rules = preload("res://scripts/rules/fuse_rules.gd")
const Settings = preload("res://scripts/settings.gd")
const HouseRules = preload("res://scripts/rules/house_rules.gd")
const WalkLayer = preload("res://scripts/walk_layer.gd")

const IMAGES := "res://assets/images/"
const HIGHLIGHT := Color("ffd76a")
const UI_COLOURS := {
	"blue": Color("2f6fd6"), "yellow": Color("e8c62e"), "white": Color("f2f2f2"), "black": Color("1e1e1e"),
	"red": Color("d0473c"), "green": Color("4caf50"), "gold": Color("d4af37"),
}
# Each symbol's own fixed colour (spec 08b). Not its wire colour: the legend is
# shuffled every game, so a symbol in its wire colour would give the answer away.
const SYMBOL_COLOURS := {
	"star": Color("f5c242"), "bell": Color("d64541"), "tree": Color("3fa34d"), "snowflake": Color("7cc6ea"),
}
const LAMP_OFF := Color("d8cbb8")
const ROOM_DARK := Color(0.04, 0.03, 0.03, 0.62)  # a room on the house plan, fuse off (spec 05)
const ROOM_LIT := Color(1.0, 0.86, 0.5, 0.12)     # a room on the house plan, fuse on
const ROOM_LIT_EDGE := Color(1.0, 0.8, 0.4, 0.9)
const ROOM_TEXT_ON_LIT := Color("fff3d6")

# Everything on a picture is measured in the picture's own pixels (all pictures are
# 1376 x 768) and moves and scales with the picture, whatever the window's shape (spec 08b).
# If a new picture moves things, change these numbers.
const PICTURE_SIZE := Vector2(1376, 768)
# room_hall.webp, left to right (the arrow keys follow this order).
const SPOTS := [
	{"name": "fuse_box", "node": "FuseBoxButton", "rect": Rect2(0, 85, 100, 245)},
	{"name": "living_room", "node": "Door_living_room", "rect": Rect2(175, 40, 150, 650)},
	{"name": "wreath", "node": "StoryWreath", "rect": Rect2(198, 146, 112, 250)},   # story (spec 25), on the door
	{"name": "bathroom", "node": "Door_bathroom", "rect": Rect2(356, 180, 108, 375)},
	{"name": "attic", "node": "StairsButton", "rect": Rect2(690, 178, 300, 392)},
	{"name": "bedroom", "node": "Door_bedroom", "rect": Rect2(1018, 40, 162, 650)},
	{"name": "house_plan", "node": "HousePlanButton", "rect": Rect2(1195, 70, 181, 290)},
]
# ui_fuse_box.webp (the modern box, second test round): the four cables hanging from the
# terminal block (left to right) and the three breakers. A solved fuse shows its breaker
# from ui_fuse_box_on.webp (all breakers up), cut out at the same place.
const WIRE_RECTS := {
	"blue": Rect2(540, 470, 88, 245), "yellow": Rect2(628, 470, 62, 245),
	"white": Rect2(690, 470, 88, 245), "black": Rect2(778, 470, 57, 245),
}
const BREAKER_RECTS := {"red": Rect2(560, 238, 62, 92), "green": Rect2(660, 238, 60, 92),
		"gold": Rect2(760, 238, 61, 92)}
# ui_house_plan.webp: the rooms by fuse index (living room, bathroom, bedroom) and the
# inner part of the empty legend box.
const PLAN_ROOMS := [Rect2(349, 317, 266, 231), Rect2(424, 140, 190, 164), Rect2(765, 262, 236, 205)]
const LEGEND_BOX := Rect2(892, 530, 298, 111)
# Hall polish (first full test round): the doll on the stairs, sounds.
# Story objects (spec 25): not part of a puzzle, they tell who Scary Jingles was.
const STORIES := {
	"wreath": {"hint": "A dried-up wreath", "sound": "sfx_easter_egg.mp3",
		"text": "A dried-up wreath. A faded tag still hangs from the bow:\n\n[i]\"For Jingles, my best little elf.\nMerry Christmas! – S.\"[/i]"},
}
const STORY_SOUND_SECONDS := 2.0  # only the start of the bells
const DOLL_RECT := Rect2(872, 398, 72, 144)  # sitting on a lower step, on the right, under the stairs label
const DOLL_DIMMED := Color(0.7, 0.65, 0.65)  # in the dim back of the hall
const DOLL_TURN_SECONDS := 1.5
const SOUNDS := "res://assets/sounds/"


# -1 means: a new random puzzle at every start. Tests set a fixed seed.
@export var seed_value := -1
@export var solo := false  # offline only: play as one player (online the game says it)
var net: Node = null  # set by main.gd for online play
var walking: Control = null  # the walking figures (spec 19), only online; hidden behind close-ups
var sounds_played: Array[String] = []  # sounds played (or, in the headless tests, that would have been)

var puzzle: Dictionary
var current_player := 0
var chosen: Array = []  # the cables clicked so far, in order
var penalty_total := 0
var _spot_index := 0  # highlighted spot in the hall (keys)
var _wire_index := 0  # highlighted cable in the fuse box (keys)

# Nodes we change later (built in _build_ui)
var _spot_buttons: Array[Button] = []
var _spot_by_name := {}
var _doors := {}             # place -> door spot (spec 07)
var _stairs: Button
var _fuse_panel: Control     # fuse box close-up
var _fuse_area: Control      # the fuse box picture's area
var _house_plan_panel: Control
var _sockets := {}           # fuse colour -> fuse picture in its socket
var _wire_buttons := {}
var _fuse_title: Label
var _hint_label: RichTextLabel  # rich text: the fuse's name in its colour
var _label_symbols: Array[TextureRect] = []
var _chosen_label: Label
var _chosen_wires: Array[Panel] = []  # the order so far as colour bars
var _legend_entries := {}    # symbol -> "star = white"
var _average_colours := {}   # picture file -> its average colour (worked out once)
var _lamps: Array[Label] = []
var _tiles: Array[PanelContainer] = []
var _lit_before: Array[bool] = [false, false, false]
var _flicker: ColorRect        # dark overlay that flickers (spec 05)
var _flicker_timer: Timer
var _flicker_rng := RandomNumberGenerator.new()
var _flicker_steps: Array = []  # what is left of the current flicker cycle
var _player_buttons: Array[Button] = []
var _penalty_label: Label
var _label_frame: PanelContainer   # the order's symbols, framed in the colour of their fuse
var _fuse_hint: RichTextLabel      # hints that grow clearer after wrong tries
var _wrong_tries := 0              # this player's wrong orders for their own fuse
var _seen_penalty := 0             # online: to notice a wrong order by anyone (sparks)
var _seen_solved := 0              # online: to notice a fuse going on, whoever did it (click, spec 22)
var _doll: TextureRect
var _spark: AudioStreamPlayer
var _creak: AudioStreamPlayer
var _click: AudioStreamPlayer      # a fuse snaps in (spec 22)
var _doll_turned := false  # she is looking at the players right now
var _note_panel: Control    # single player: the note by the doll with the wire order
var _note_symbols: Array[TextureRect] = []
var _mission_card: Control
var _story_card: Control        # a story note (spec 25), on this device only
var _story_text: RichTextLabel
var _story_sound: AudioStreamPlayer
# The mission card shows once per game: the first time the team stands in the hall.
# Remembered by the game's own random puzzle, so a new game shows it again.
static var _mission_seen_for := ""
const MISSION_TEXT := """[font_size=30][b]🎄 Your mission[/b][/font_size]

Scary Jingles has stolen three presents. Bring them back before midnight!

[b]You are one team: talk to each other![/b]

•  [b]Look into every room first:[/b] what you find in one room may help in another.
•  [b]Solve the puzzles,[/b] and collect the presents and anything that seems important.

⏰ 20 minutes until midnight."""
# Single player: the same mission, without the team.
const MISSION_TEXT_ALONE := """[font_size=30][b]🎄 Your mission[/b][/font_size]

Scary Jingles has stolen three presents. Bring them back before midnight!

[b]You are on your own tonight. Look closely![/b]

•  [b]Look into every room first:[/b] what you find in one room may help in another.
•  [b]Solve the puzzles,[/b] and collect the presents and anything that seems important.

⏰ 20 minutes until midnight."""
var _message: Label
var _last_event := ""  # the game event shown last: a tick with no new event keeps our own message


func _ready() -> void:
	if _online():
		current_player = net.my_index
		_take_game()
		_seen_penalty = net.game.get("penalty_seconds", 0)
		_seen_solved = _solved_count()  # fuses already on when we come back: no click
		net.game_changed.connect(_on_game_changed)
	else:
		var rng := RandomNumberGenerator.new()
		if seed_value >= 0:
			rng.seed = seed_value
		else:
			rng.randomize()
		puzzle = Rules.create_puzzle(rng)
	_build_ui()
	if _online():
		for button in _player_buttons:
			button.visible = false  # each device is one player
		_message.text = net.game["last_event"]
		_last_event = net.game["last_event"]
	_refresh()
	_show_mission(_mission_seen_for != _mission_key())  # once per game, at the first visit


func _online() -> bool:
	return net != null and not net.game.is_empty()


# Online: copy what we show from the shared game.
func _take_game() -> void:
	puzzle = net.game["puzzle"]
	penalty_total = net.game["penalty_seconds"]


func _on_game_changed() -> void:
	if not _online():
		return  # game is over (host left); main.gd switches the screen
	_take_game()
	# Only a new event replaces the message (playtest: "still dark" vanished at every clock tick).
	if net.game["last_event"] != _last_event:
		_last_event = net.game["last_event"]
		_message.text = _last_event
	_notice_wrong_order(net.game)
	_notice_fuse_on()
	_refresh()


# Online: a wrong order by anyone sparks on every device; our own counts for the hints.
func _notice_wrong_order(game: Dictionary) -> void:
	var penalty: int = game.get("penalty_seconds", 0)
	var event: String = game.get("last_event", "")
	if penalty > _seen_penalty and "wrong order" in event:
		_play(_spark, "sfx_spark.mp3")
		if event.begins_with("Player %d:" % (current_player + 1)):
			_wrong_tries += 1
	_seen_penalty = penalty


# ---------- reacting to clicks ----------

func _on_fuse_box_pressed() -> void:
	_house_plan_panel.visible = false
	_fuse_panel.visible = true
	_show_figures(false)
	_refresh()


func _on_house_plan_pressed() -> void:
	_fuse_panel.visible = false
	_house_plan_panel.visible = true
	_show_figures(false)


func _close_close_ups() -> void:
	_fuse_panel.visible = false
	_house_plan_panel.visible = false
	_note_panel.visible = false
	_show_figures(true)


# Single player, or not: the game says it online; offline the hall's own switch.
func _alone() -> bool:
	return net.game.get("solo", false) if _online() else solo


# The doll on the stairs: she turns her head; alone, a note lies by her with the wire order.
func _on_doll_pressed() -> void:
	_doll_turns()
	if _alone():
		_fuse_panel.visible = false
		_house_plan_panel.visible = false
		_note_panel.visible = true
		_show_figures(false)
		var label := Rules.label_for(puzzle, 0)
		for i in _note_symbols.size():
			_show_symbol(_note_symbols[i], label[i])
		_message.text = "A crumpled note lies by the doll."


# The figures are drawn by depth and would cover a close-up, so they step aside.
func _show_figures(shown: bool) -> void:
	if walking != null:
		walking.visible = shown


func _on_player_pressed(player: int) -> void:
	current_player = player
	chosen.clear()
	_message.text = ""
	_refresh()


# A click on a cable (or Enter on it): it is next in the order. With all four, try it.
func _on_wire_pressed(colour: String) -> void:
	if puzzle["fuses"][current_player]["solved"] or colour in chosen:
		return
	chosen.append(colour)
	if chosen.size() == Settings.WIRE_COLOURS.size():
		_submit_attempt()
	_refresh()


# Walking (spec 07): the whole team goes; the host checks the door is lit.
func _on_place_pressed(place: String) -> void:
	if _online():
		net.send_action("go_to", {"place": place})
	else:
		_message.text = "Walking through the house needs the full game: start main.tscn."


func _on_reset_pressed() -> void:
	chosen.clear()
	_refresh()


# Four cables chosen: ask the rules, then show the result. The order starts again.
func _submit_attempt() -> void:
	var wires := chosen.duplicate()
	chosen.clear()
	if _online():
		net.send_action("try_fuse", {"wires": wires})  # the host decides
		return
	var fuse: Dictionary = puzzle["fuses"][current_player]
	var result := Rules.try_fuse_alone(puzzle, wires) if _alone() else Rules.try_fuse(puzzle, current_player, wires)
	if result["error"] != "":
		_message.text = result["error"]
	elif result["correct"]:
		_message.text = "The %s fuse is on! The %s is lit." % [fuse["colour"], fuse["room"]]
		if _alone():
			_message.text = "All three breakers flip up. Every room is lit!"
		_play(_click, "sfx_fuse_click.mp3")
	else:
		penalty_total += result["penalty_seconds"]
		_message.text = "Sparks! -%d s" % result["penalty_seconds"]
		_wrong_tries += 1
		_play(_spark, "sfx_spark.mp3")


# ---------- coloured symbols (spec 08b) ----------

# Shows Gloria's symbol picture in the symbol's colour. The pictures are dark
# brown, and Godot tints by multiplying: shown = picture colour x self_modulate.
# So the factor is wanted colour / the picture's average colour (above 1 is fine).
func _show_symbol(picture: TextureRect, symbol: String) -> void:
	var file := IMAGES + "sym_%s.png" % symbol
	picture.texture = load(file)
	var average := _average_colour(file)
	var wanted: Color = SYMBOL_COLOURS[symbol]
	picture.self_modulate = Color(wanted.r / average.r, wanted.g / average.g, wanted.b / average.b)


# The average colour of a picture's visible pixels (every second pixel is enough).
func _average_colour(file: String) -> Color:
	if not _average_colours.has(file):
		var image: Image = load(file).get_image()
		if image.is_compressed():
			image.decompress()
		var sum := Color(0, 0, 0, 0)
		var count := 0
		for y in range(0, image.get_height(), 2):
			for x in range(0, image.get_width(), 2):
				var pixel := image.get_pixel(x, y)
				if pixel.a > 0.5:
					sum += pixel
					count += 1
		count = maxi(count, 1)
		_average_colours[file] = Color(maxf(sum.r / count, 0.01), maxf(sum.g / count, 0.01), maxf(sum.b / count, 0.01))
	return _average_colours[file]


# ---------- keys (like the bathroom, spec 10) ----------

func _unhandled_input(event: InputEvent) -> void:
	if _story_card.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			_close_story()
		else:
			return
	elif _fuse_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_close_ups()
		elif event.is_action_pressed("ui_left"):
			_move_wire(-1)
		elif event.is_action_pressed("ui_right"):
			_move_wire(1)
		elif event.is_action_pressed("ui_accept"):
			if not _wire_buttons[highlighted_wire()].disabled:
				_on_wire_pressed(highlighted_wire())
		else:
			return
	elif _house_plan_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			_close_close_ups()
		else:
			return
	else:
		if event.is_action_pressed("ui_left"):
			_move_spot(-1)
		elif event.is_action_pressed("ui_right"):
			_move_spot(1)
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up"):
			_use_spot(highlighted_spot())
		else:
			return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func highlighted_spot() -> String:
	return SPOTS[_spot_index]["name"]


func highlighted_wire() -> String:
	return Settings.WIRE_COLOURS[_wire_index]


func _move_spot(step: int) -> void:
	_spot_index = clampi(_spot_index + step, 0, SPOTS.size() - 1)
	_refresh()


func _move_wire(step: int) -> void:
	_wire_index = clampi(_wire_index + step, 0, Settings.WIRE_COLOURS.size() - 1)
	_refresh()


func _on_spot_pressed(index: int) -> void:
	_spot_index = index
	_use_spot(highlighted_spot())


# A spot used by click or key. A dark door says which fuse it needs.
func _use_spot(spot: String) -> void:
	match spot:
		"fuse_box":
			_on_fuse_box_pressed()
		"house_plan":
			_on_house_plan_pressed()
		"wreath":
			_show_story(spot)
		_:
			if _spot_by_name[spot].disabled:
				_message.text = _why_dark(spot)
				if spot == "attic":
					_doll_turns()
			else:
				_on_place_pressed(spot)
	_refresh()


# A dark door or the dark stairs are switched off, so a click would do nothing: here it
# still explains why (like the keys do), and on the stairs the doll may turn her head.
func _on_spot_input(event: InputEvent, index: int) -> void:
	var button: Button = _spot_buttons[index]
	if button.disabled and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_spot_pressed(index)


# The doll on the stairs turns her head towards the players, with a slow creak, then
# back. Every click on the dark stairs makes her turn (not again while she is turned).
func _doll_turns() -> void:
	if _doll_turned:
		return
	_doll_turned = true
	_doll.texture = load(IMAGES + "prop_doll_turned.png")
	_doll.modulate = Color.WHITE  # for a moment the lamp lights her up
	_play(_creak, "sfx_creak.mp3")
	get_tree().create_timer(DOLL_TURN_SECONDS).timeout.connect(_doll_turns_back)


func _doll_turns_back() -> void:
	_doll_turned = false
	_doll.texture = load(IMAGES + "prop_doll.png")
	_doll.modulate = DOLL_DIMMED


# Online (spec 22): a fuse went on, whoever solved it: its click on every device.
func _notice_fuse_on() -> void:
	var solved := _solved_count()
	if solved > _seen_solved:
		_play(_click, "sfx_fuse_click.mp3")
	_seen_solved = solved


func _solved_count() -> int:
	var count := 0
	for fuse in puzzle["fuses"]:
		if fuse["solved"]:
			count += 1
	return count


func _play(player: AudioStreamPlayer, file_name: String) -> void:
	sounds_played.append(file_name)
	if DisplayServer.get_name() != "headless":
		player.play()  # not in the test run: no sound card


# ---------- the mission card (second test round) ----------

# ---------- story objects (spec 25) ----------

# Shows the object's note on this device. Nothing goes to the host, nothing changes.
func _show_story(spot: String) -> void:
	var story: Dictionary = STORIES[spot]
	_story_text.text = story["text"]
	_story_card.visible = true
	_show_figures(false)  # the figures stood in front of the note (spec 29)
	_story_sound.stream = load(SOUNDS + story["sound"])
	sounds_played.append(story["sound"])
	if DisplayServer.get_name() != "headless":  # not in the test run: no sound card
		_story_sound.play()
		get_tree().create_timer(STORY_SOUND_SECONDS).timeout.connect(_story_sound.stop)


func _close_story() -> void:
	_story_card.visible = false
	_show_figures(not _mission_card.visible and not _fuse_panel.visible and not _house_plan_panel.visible)


# A click anywhere closes the note.
func _on_story_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_story()


func _build_story_card() -> void:
	_story_card = Control.new()
	_story_card.name = "StoryCard"
	_story_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_card.visible = false
	_story_card.gui_input.connect(_on_story_card_input)
	add_child(_story_card)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_PASS  # the click reaches the card, which closes
	_story_card.add_child(shade)
	var paper := TextureRect.new()  # the same paper as the mission note
	paper.texture = load(IMAGES + "prop_note.png")
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.mouse_filter = Control.MOUSE_FILTER_PASS
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.offset_left = -270
	paper.offset_right = 270
	paper.offset_top = -170
	paper.offset_bottom = 170
	_story_card.add_child(paper)
	_story_text = RichTextLabel.new()
	_story_text.name = "StoryText"
	_story_text.bbcode_enabled = true
	_story_text.scroll_active = false
	_story_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_text.offset_left = 60
	_story_text.offset_right = -50
	_story_text.offset_top = 60
	_story_text.offset_bottom = -60
	_story_text.add_theme_font_size_override("normal_font_size", 22)
	_story_text.add_theme_font_size_override("italics_font_size", 22)
	_story_text.add_theme_color_override("default_color", Color("3b2a1a"))
	paper.add_child(_story_text)
	var hint := Label.new()
	hint.text = "Click to close"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.23, 0.16, 0.1, 0.6))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -60
	hint.offset_right = 60
	hint.offset_top = -48
	hint.offset_bottom = -26
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(hint)


# What stays the same during one game: the legend and the fuses' orders. Not their
# "solved" state, else the card came back after each fuse (playtest, spec 29).
func _mission_key() -> String:
	var orders := []
	for fuse in puzzle.get("fuses", []):
		orders.append(fuse.get("order", []))
	return str(puzzle.get("legend", {})) + str(orders)


func _show_mission(shown: bool) -> void:
	_mission_card.visible = shown
	_show_figures(not shown and not _fuse_panel.visible and not _house_plan_panel.visible)


func _close_mission() -> void:
	_mission_seen_for = _mission_key()
	_show_mission(false)


# For tests: the next hall shows the card again, as at the start of a new game.
static func forget_mission() -> void:
	_mission_seen_for = ""


func _build_mission_card() -> void:
	_mission_card = Control.new()
	_mission_card.name = "MissionCard"
	_mission_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_mission_card)
	var shade := ColorRect.new()  # catches clicks, so the hall waits until the card is read
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mission_card.add_child(shade)
	var paper := TextureRect.new()  # the empty note from the living room
	paper.texture = load(IMAGES + "prop_note.png")
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.offset_left = -330
	paper.offset_right = 330
	paper.offset_top = -300
	paper.offset_bottom = 300
	_mission_card.add_child(paper)
	var text := RichTextLabel.new()
	text.name = "MissionText"
	text.bbcode_enabled = true
	text.text = MISSION_TEXT_ALONE if _alone() else MISSION_TEXT
	text.scroll_active = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 70
	text.offset_right = -60
	text.offset_top = 70
	text.offset_bottom = -110
	text.add_theme_font_size_override("normal_font_size", 21)
	text.add_theme_font_size_override("bold_font_size", 21)
	for colour_name in ["default_color"]:
		text.add_theme_color_override(colour_name, Color("3b2a1a"))
	paper.add_child(text)
	var go := Button.new()
	go.name = "MissionGo"
	go.text = "Let's go!"
	go.add_theme_font_size_override("font_size", 22)
	go.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	go.offset_left = -80
	go.offset_right = 80
	go.offset_top = -95
	go.offset_bottom = -45
	go.pressed.connect(_close_mission)
	paper.add_child(go)
	# The "?" (top right, after the penalty, next to Pause) opens the card again (spec 29).
	var again := Button.new()
	again.name = "MissionButton"
	again.text = "?"
	again.tooltip_text = "Your mission"
	again.add_theme_font_size_override("font_size", 22)
	again.custom_minimum_size = Vector2(44, 44)
	again.focus_mode = Control.FOCUS_NONE
	ButtonStyle.make_clickable(again)
	again.pressed.connect(_show_mission.bind(true))
	get_node("Hud").add_child(again)


func _why_dark(place: String) -> String:
	if place == "attic":
		return "The stairs are pitch dark. Turn on all three fuses first."
	for fuse in Settings.FUSES:
		if fuse["place"] == place:
			return "The %s is still dark. Turn on the %s fuse first." % [fuse["room"], fuse["colour"]]
	return ""


# ---------- showing the current state ----------

func _refresh() -> void:
	var lit := Rules.lit_rooms(puzzle)

	# House plan close-up: legend and the rooms (darkened, or their own colour with a warm edge).
	for symbol in Settings.SYMBOLS:
		_legend_entries[symbol].text = "%s = %s" % [symbol, puzzle["legend"][symbol]]
	for i in _lamps.size():
		var fuse_info: Dictionary = Settings.FUSES[i]
		var is_lit: bool = puzzle["fuses"][i]["room"] in lit
		_lamps[i].text = "%s\n%s" % [_door_label(fuse_info["place"]), "lit" if is_lit else "dark"]
		_lamps[i].add_theme_color_override("font_color", ROOM_TEXT_ON_LIT if is_lit else LAMP_OFF)
		_tiles[i].add_theme_stylebox_override("panel", _tile_style(is_lit))
		if is_lit and not _lit_before[i]:
			_glow(_tiles[i])
		_lit_before[i] = is_lit
	_update_flicker(lit.size())

	# Spots: the highlighted one has a golden frame.
	for i in _spot_buttons.size():
		var border := HIGHLIGHT if i == _spot_index else Color(1, 1, 1, 0.12)
		_spot_buttons[i].add_theme_stylebox_override("normal", _spot_style(border))
		_spot_buttons[i].add_theme_stylebox_override("disabled", _spot_style(border if i == _spot_index else Color(1, 1, 1, 0.05)))
	# Doors open with their fuse; the stairs with all three (spec 07).
	for fuse in Settings.FUSES:
		var door: Button = _doors[fuse["place"]]
		var is_open: bool = fuse["room"] in lit
		door.disabled = not is_open
		door.text = _door_label(fuse["place"]) + ("" if is_open else " (dark)")
	_stairs.disabled = lit.size() < Settings.FUSES.size()
	_stairs.text = "Attic stairs" + ("" if not _stairs.disabled else " (dark)")

	for i in _player_buttons.size():
		_player_buttons[i].button_pressed = (i == current_player)
	_penalty_label.text = "Penalty: %d s" % penalty_total

	# Fuse box close-up.
	var fuse: Dictionary = puzzle["fuses"][current_player]
	_fuse_title.text = "Player %d, your fuse: %s" % [current_player + 1, fuse["colour"].to_upper()]
	_fuse_title.add_theme_color_override("font_color", UI_COLOURS[fuse["colour"]])
	var seen := _fuse_seen_by(current_player)
	var seen_colour: String = puzzle["fuses"][seen]["colour"]
	var label := Rules.label_for(puzzle, seen)
	var coloured_name := "[color=#%s]%s[/color]" % [UI_COLOURS[seen_colour].to_html(false), seen_colour.to_upper()]
	# The order is shown as if it were the player's own; only its frame tells whose it is.
	_hint_label.text = "Connect the four wires in the right order. [i]Not every order you see is meant for you.[/i]\n\n[b]The order:[/b]"
	for i in _label_symbols.size():
		_show_symbol(_label_symbols[i], label[i])
	_label_frame.add_theme_stylebox_override("panel", _box(Color(0.05, 0.03, 0.03, 0.6), UI_COLOURS[seen_colour], 8))
	_label_frame.visible = not _alone()
	# Hints that grow clearer: after one wrong try a question, after two the answer.
	if fuse["solved"] and not puzzle["fuses"][seen]["solved"]:
		_fuse_hint.text = "Your fuse is on. But these symbols are still here... someone else might need them."
	elif _wrong_tries >= Settings.RESCUE_TRIES and not fuse["solved"]:
		_fuse_hint.text = "[b]Sparks![/b] Look at the frame: these symbols belong to the %s fuse. Who has it?" % coloured_name
	elif _wrong_tries >= 1 and not fuse["solved"]:
		_fuse_hint.text = "[b]Sparks![/b] Are these symbols really meant for [i]your[/i] fuse?"
	else:
		_fuse_hint.text = ""
	if _alone():  # one player: one order for all three fuses, hidden by the doll
		_fuse_title.text = "Your fuses: all three"
		_hint_label.text = "Connect the four wires in the right order. [i]The order is hidden somewhere in the hall...[/i]"
		_fuse_hint.text = "" if fuse["solved"] or _wrong_tries == 0 else \
				"[b]Sparks![/b] Did you find the order? Someone on the stairs keeps an eye on it."
	for i in Settings.FUSES.size():
		var colour: String = puzzle["fuses"][i]["colour"]
		_sockets[colour].visible = puzzle["fuses"][i]["solved"]
	for i in Settings.WIRE_COLOURS.size():
		var colour: String = Settings.WIRE_COLOURS[i]
		var wire: Button = _wire_buttons[colour]
		wire.disabled = fuse["solved"] or colour in chosen
		var border := HIGHLIGHT if i == _wire_index else Color(1, 1, 1, 0.15)
		wire.add_theme_stylebox_override("normal", _spot_style(border))
		wire.add_theme_stylebox_override("disabled", _spot_style(Color(0, 0, 0, 0.4)))
	if fuse["solved"]:
		_chosen_label.text = "This fuse is already on."
	elif chosen.is_empty():
		_chosen_label.text = "Your order: click the wires"
	else:
		_chosen_label.text = "Your order: " + ", ".join(chosen)
	for i in _chosen_wires.size():
		_chosen_wires[i].visible = i < chosen.size()
		if i < chosen.size():
			_chosen_wires[i].add_theme_stylebox_override("panel", _box(UI_COLOURS[chosen[i]], Color(0, 0, 0, 0.7), 0))


# The fuse whose torn label this player can see.
func _fuse_seen_by(player: int) -> int:
	for i in Settings.FUSES.size():
		if Rules.label_viewer(i) == player:
			return i
	return -1


func _door_label(place: String) -> String:
	return {"living_room": "Living room", "bathroom": "Bathroom", "bedroom": "Bedroom"}.get(place, place)


# ---------- atmosphere (spec 05) ----------

# How dark the flicker may get: strongest with 0 fuses on, 0 with all fuses on.
static func flicker_strength(lit_count: int) -> float:
	var total := Settings.FUSES.size()
	return Settings.FLICKER_MAX_DARKNESS * float(total - clampi(lit_count, 0, total)) / total


# One flicker cycle like a loose bulb, as steps [darkness, seconds]:
# a calm pause first, then a short burst of 2 to 4 quick dips.
static func flicker_cycle(rng: RandomNumberGenerator, strength: float) -> Array:
	var steps := [[0.0, rng.randf_range(Settings.FLICKER_PAUSE_MIN_SECONDS, Settings.FLICKER_PAUSE_MAX_SECONDS)]]
	for i in rng.randi_range(2, 4):
		steps.append([strength * rng.randf_range(0.5, 1.0), rng.randf_range(0.04, 0.09)])  # dip
		steps.append([0.0, rng.randf_range(0.05, 0.12)])                                # light back
	return steps


func flicker_active() -> bool:
	return _flicker_timer != null and not _flicker_timer.is_stopped()


func _update_flicker(lit_count: int) -> void:
	if flicker_strength(lit_count) <= 0.0:
		_flicker_timer.stop()
		_flicker_steps.clear()
		_flicker.color.a = 0.0  # power is back: steady light
	elif _flicker_timer.is_stopped():
		_flicker_timer.start(0.1)


# Next step of the cycle; a new cycle (with the current strength) when one is done.
func _on_flicker_tick() -> void:
	if _flicker_steps.is_empty():
		_flicker_steps = flicker_cycle(_flicker_rng, flicker_strength(Rules.lit_rooms(puzzle).size()))
	var step: Array = _flicker_steps.pop_front()
	_flicker.color.a = step[0]
	_flicker_timer.start(step[1])


# A room on the plan flashes bright for a moment when its light comes on.
func _glow(tile: Control) -> void:
	tile.modulate = Color(1.8, 1.8, 1.8)
	create_tween().tween_property(tile, "modulate", Color.WHITE, 0.8)


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var hall_area := _picture_area(self, "Background", "room_hall.webp")
	if _online():  # the figures walk here (spec 19); the spots are added after, so they stay on top
		walking = WalkLayer.new()
		walking.net = net
		hall_area.add_child(walking)
	# The doll on the stairs (hall polish): dimmed, under the spots so the stairs stay clickable.
	_doll = _image("Doll", "prop_doll.png")
	_doll.modulate = DOLL_DIMMED
	_doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_doll, DOLL_RECT)
	hall_area.add_child(_doll)

	# The spots: see-through buttons over the picture, with a name.
	for i in SPOTS.size():
		var spot: Dictionary = SPOTS[i]
		var button := Button.new()
		_style_spot(button, spot["node"], 16)
		_place(button, spot["rect"])
		button.pressed.connect(_on_spot_pressed.bind(i))
		button.gui_input.connect(_on_spot_input.bind(i))
		hall_area.add_child(button)
		_spot_buttons.append(button)
		_spot_by_name[spot["name"]] = button
		if spot["name"] == "attic":
			_stairs = button
		elif spot["name"] in ["living_room", "bathroom", "bedroom"]:
			_doors[spot["name"]] = button
	_spot_by_name["fuse_box"].text = "Fuse box"
	_spot_by_name["house_plan"].text = "House plan"
	# The doll can be clicked herself (above the stairs): she turns, and alone she has a note.
	var doll_spot := Button.new()
	_style_spot(doll_spot, "DollSpot", 14)
	doll_spot.tooltip_text = "The doll"
	_place(doll_spot, DOLL_RECT)
	doll_spot.pressed.connect(_on_doll_pressed)
	hall_area.add_child(doll_spot)
	for story in STORIES:
		_spot_by_name[story].tooltip_text = STORIES[story]["hint"]  # no name on it, a hint on hover
	_story_sound = AudioStreamPlayer.new()
	_story_sound.name = "StorySound"
	add_child(_story_sound)

	_build_fuse_box()
	_build_house_plan()
	_build_note()

	# On top of everything: title, player switch and penalty, the message line.
	var title := _label(self, "The Hall", 34)
	title.position = Vector2(24, 12)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	_outline(title)
	var hud := HBoxContainer.new()
	hud.name = "Hud"
	hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud.offset_left = -620
	hud.offset_right = -144  # room for Pause (main.gd) at the right edge, spec 29
	hud.offset_top = 12
	hud.offset_bottom = 56
	hud.alignment = BoxContainer.ALIGNMENT_END
	hud.add_theme_constant_override("separation", 8)
	add_child(hud)
	for i in Settings.FUSES.size():
		var button := Button.new()
		button.name = "PlayerButton%d" % i
		button.text = "Player %d" % (i + 1)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_player_pressed.bind(i))
		hud.add_child(button)
		_player_buttons.append(button)
	_penalty_label = _label(hud, "", 20)
	_penalty_label.name = "PenaltyLabel"
	_penalty_label.add_theme_color_override("font_color", Color("ff8a80"))
	_outline(_penalty_label)
	_message = _label(self, "", 22, true)
	_message.name = "Message"
	_message.anchor_top = 1.0
	_message.anchor_bottom = 1.0
	_message.offset_left = 24
	_message.offset_right = 584
	_message.offset_top = -52
	_message.offset_bottom = -12
	_message.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_message.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_message.add_theme_color_override("font_color", Color("ffd76a"))
	_outline(_message)

	# Flickering light (spec 05): a dark layer over everything that lets clicks through.
	_flicker = ColorRect.new()
	_flicker.name = "FlickerOverlay"
	_flicker.color = Color(0, 0, 0, 0)
	_flicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flicker)
	_flicker_rng.randomize()
	_flicker_timer = Timer.new()
	_flicker_timer.name = "FlickerTimer"
	_flicker_timer.one_shot = true
	_flicker_timer.timeout.connect(_on_flicker_tick)
	add_child(_flicker_timer)

	# Sounds (hall polish): sparks for a wrong order, a creak for the doll.
	_spark = AudioStreamPlayer.new()
	_spark.name = "SparkSound"
	_spark.stream = load(SOUNDS + "sfx_spark.mp3")
	add_child(_spark)
	_creak = AudioStreamPlayer.new()
	_creak.name = "CreakSound"
	_creak.stream = load(SOUNDS + "sfx_creak.mp3")
	_creak.pitch_scale = 0.8  # slower and lower: creepier for the doll
	add_child(_creak)

	_build_story_card()    # over the hall and the flicker, under the mission card (spec 25)
	_build_mission_card()  # on top of everything, also the flicker
	_click = AudioStreamPlayer.new()
	_click.name = "FuseClickSound"
	_click.stream = load(SOUNDS + "sfx_fuse_click.mp3")
	add_child(_click)


# Fuse box close-up: the box picture, cables to click, fuses in their sockets, and a
# side panel with the player's fuse, the torn label and the order so far.
func _build_fuse_box() -> void:
	_fuse_panel = _close_up("FusePanel")
	_fuse_area = _picture_area(_fuse_panel, "FuseBoxPicture", "ui_fuse_box.webp")
	var on_picture: Texture2D = load(IMAGES + "ui_fuse_box_on.webp")
	var to_texture := Vector2(on_picture.get_size()) / PICTURE_SIZE
	for colour in BREAKER_RECTS:
		var rect: Rect2 = BREAKER_RECTS[colour]
		var piece := AtlasTexture.new()  # this one breaker, switched on
		piece.atlas = on_picture
		piece.region = Rect2(rect.position * to_texture, rect.size * to_texture)
		var breaker := _image("BreakerOn_" + colour, "")
		breaker.texture = piece
		breaker.stretch_mode = TextureRect.STRETCH_SCALE
		_place(breaker, rect)
		breaker.visible = false
		_fuse_area.add_child(breaker)
		_sockets[colour] = breaker
	for i in Settings.WIRE_COLOURS.size():
		var colour: String = Settings.WIRE_COLOURS[i]
		var rect: Rect2 = WIRE_RECTS[colour]
		var wire := Button.new()
		_style_spot(wire, "Wire_" + colour, 13)
		_place(wire, rect)
		wire.pressed.connect(_on_wire_pressed.bind(colour))
		_fuse_area.add_child(wire)
		_wire_buttons[colour] = wire
		# The cable's name above it, in two rows so neighbouring names don't touch.
		var name_label := _label(_fuse_area, colour, 13)
		name_label.name = "WireName_" + colour
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(name_label, Rect2(rect.get_center().x - 40, 380 + (i % 2) * 22, 80, 24))  # above the terminal block
		_outline(name_label)

	var side := PanelContainer.new()
	side.name = "FuseInfo"
	side.position = Vector2(20, 64)
	side.size = Vector2(360, 470)
	side.add_theme_stylebox_override("panel", _box(Color(0.1, 0.06, 0.06, 0.88), Color("5c2a22"), 14))
	_fuse_panel.add_child(side)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	side.add_child(box)
	_fuse_title = _label(box, "", 24, true)
	_fuse_title.name = "FuseTitle"
	var space := Control.new()  # a bit more room under the title (manual test 4)
	space.custom_minimum_size = Vector2(0, 4)
	box.add_child(space)
	_hint_label = RichTextLabel.new()
	_hint_label.name = "LabelHint"
	_hint_label.bbcode_enabled = true
	_hint_label.fit_content = true
	_hint_label.scroll_active = false
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.add_theme_font_size_override("normal_font_size", 17)
	_hint_label.add_theme_color_override("default_color", Color("c9b8a0"))
	box.add_child(_hint_label)
	_label_frame = PanelContainer.new()
	_label_frame.name = "LabelFrame"
	box.add_child(_label_frame)
	var symbols := HBoxContainer.new()
	symbols.name = "LabelSymbols"
	symbols.add_theme_constant_override("separation", 0)
	_label_frame.add_child(symbols)
	for i in 4:
		var symbol := _image("LabelSymbol%d" % i, "")
		symbol.custom_minimum_size = Vector2(56, 56)
		symbol.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # evenly over the frame (spec 29)
		symbols.add_child(symbol)
		_label_symbols.append(symbol)
	_fuse_hint = RichTextLabel.new()
	_fuse_hint.name = "FuseHint"
	_fuse_hint.bbcode_enabled = true
	_fuse_hint.fit_content = true
	_fuse_hint.scroll_active = false
	_fuse_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fuse_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuse_hint.add_theme_font_size_override("normal_font_size", 16)
	_fuse_hint.add_theme_font_size_override("bold_font_size", 16)
	_fuse_hint.add_theme_color_override("default_color", Color("ffd76a"))
	box.add_child(_fuse_hint)
	_chosen_label = _label(box, "", 18, true)
	_chosen_label.name = "ChosenLabel"
	var wires_row := HBoxContainer.new()
	wires_row.name = "ChosenWires"
	wires_row.custom_minimum_size = Vector2(0, 24)
	wires_row.add_theme_constant_override("separation", 8)
	box.add_child(wires_row)
	for i in 4:
		var bar := Panel.new()
		bar.name = "ChosenWire%d" % i
		bar.custom_minimum_size = Vector2(60, 18)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wires_row.add_child(bar)
		_chosen_wires.append(bar)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(_plain_button("ResetButton", "Reset", _on_reset_pressed))
	buttons.add_child(_plain_button("BackFromFuseBox", "Back to the hall", _close_close_ups))
	var keys := _label(box, "The house plan shows which symbol means which wire. Keys: left/right choose, Enter takes the cable, Esc goes back.", 14, true)
	keys.add_theme_color_override("font_color", Color("9c8d7a"))


# House plan close-up: each room darkened or in its own colour, and the legend in the
# plan's empty box.
func _build_house_plan() -> void:
	_house_plan_panel = _close_up("HousePlanPanel")
	var plan_area := _picture_area(_house_plan_panel, "HousePlanPicture", "ui_house_plan.webp")
	for i in Settings.FUSES.size():
		var tile := PanelContainer.new()
		tile.name = "RoomTile%d" % i
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(tile, PLAN_ROOMS[i])
		plan_area.add_child(tile)
		_tiles.append(tile)
		var lamp := _label(tile, "", 16, true)
		lamp.name = "RoomLamp%d" % i
		lamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_outline(lamp)
		_lamps.append(lamp)
	var legend_place := CenterContainer.new()
	legend_place.name = "Legend"
	legend_place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(legend_place, LEGEND_BOX)
	plan_area.add_child(legend_place)
	var legend := VBoxContainer.new()
	legend.add_theme_constant_override("separation", 1)
	legend_place.add_child(legend)
	for symbol in Settings.SYMBOLS:
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)
		legend.add_child(entry)
		# A small dark chip behind the symbol, so its colour stands out on the paper.
		var chip := PanelContainer.new()
		chip.name = "LegendChip_" + symbol
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color("3b2a1a")
		chip_style.set_corner_radius_all(4)
		chip_style.set_content_margin_all(1)
		chip.add_theme_stylebox_override("panel", chip_style)
		entry.add_child(chip)
		var icon := _image("LegendSymbol_" + symbol, "")
		_show_symbol(icon, symbol)
		icon.custom_minimum_size = Vector2(20, 20)
		chip.add_child(icon)
		var text := _label(entry, "", 14)
		text.name = "LegendEntry_" + symbol
		text.add_theme_color_override("font_color", Color("3b2a1a"))
		_legend_entries[symbol] = text
	var back := _plain_button("BackFromPlan", "Back to the hall", _close_close_ups)
	back.position = Vector2(24, 64)
	_house_plan_panel.add_child(back)


# ---------- small helpers ----------

# A full-screen layer that catches clicks, so the hall behind stays still.
# Single player: the crumpled note by the doll, with the four symbols of the wire order.
func _build_note() -> void:
	_note_panel = _close_up("NotePanel")
	var paper := TextureRect.new()
	paper.texture = load(IMAGES + "prop_note.png")
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.offset_left = -260
	paper.offset_right = 260
	paper.offset_top = -220
	paper.offset_bottom = 220
	_note_panel.add_child(paper)
	var words := _label(paper, "Don't forget the wires... in this order:", 22, true)
	words.add_theme_color_override("font_color", Color("3b2a1a"))
	words.set_anchors_preset(Control.PRESET_TOP_WIDE)
	words.offset_left = 50
	words.offset_right = -50
	words.offset_top = 95
	words.offset_bottom = 160
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.offset_left = -170
	row.offset_right = 170
	row.offset_top = -40
	row.offset_bottom = 40
	paper.add_child(row)
	for i in 4:
		var chip := PanelContainer.new()  # a dark chip, so the coloured symbol stands out on paper
		chip.add_theme_stylebox_override("panel", _box(Color("3b2a1a"), Color("3b2a1a"), 4))
		row.add_child(chip)
		var symbol := _image("NoteSymbol%d" % i, "")
		symbol.custom_minimum_size = Vector2(60, 60)
		chip.add_child(symbol)
		_note_symbols.append(symbol)
	var back := _plain_button("BackFromNote", "Back to the hall", _close_close_ups)
	back.position = Vector2(24, 64)
	_note_panel.add_child(back)


func _close_up(node_name: String) -> Control:
	var layer := Control.new()
	layer.name = node_name
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)
	return layer


# A picture that keeps its shape (fit, centred) in any window. Returns the area exactly
# on top of the picture: children placed with _place() stay on their part of the picture.
func _picture_area(parent: Control, picture_name: String, file: String) -> Control:
	var fit := AspectRatioContainer.new()
	fit.name = picture_name + "Fit"
	fit.set_anchors_preset(Control.PRESET_FULL_RECT)
	fit.ratio = PICTURE_SIZE.x / PICTURE_SIZE.y
	fit.stretch_mode = AspectRatioContainer.STRETCH_FIT
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fit)
	var area := Control.new()
	area.name = picture_name + "Area"
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fit.add_child(area)
	var picture := TextureRect.new()
	picture.name = picture_name
	picture.texture = load(IMAGES + file)
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(picture)
	return area


# Put a node on a rect given in picture pixels (it then moves and scales with the picture).
func _place(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x / PICTURE_SIZE.x
	node.anchor_top = rect.position.y / PICTURE_SIZE.y
	node.anchor_right = rect.end.x / PICTURE_SIZE.x
	node.anchor_bottom = rect.end.y / PICTURE_SIZE.y
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


# A picture that scales into whatever size it gets.
func _image(node_name: String, file: String) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	if file != "":
		image.texture = load(IMAGES + file)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


# A see-through button over a part of a picture, its name written on it.
# No keyboard focus: the hall handles the keys itself (bug from manual test 2).
func _style_spot(button: Button, node_name: String, font_size: int) -> void:
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_color_override("font_hover_color", HIGHLIGHT)
	button.add_theme_color_override("font_disabled_color", Color(0.8, 0.75, 0.7))
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_stylebox_override("hover", _spot_style(HIGHLIGHT))
	button.add_theme_stylebox_override("pressed", _spot_style(HIGHLIGHT))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND  # like in every room (spec 25)


func _plain_button(node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


func _spot_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style


# A room on the house plan: square, exactly over the room.
func _tile_style(is_lit: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ROOM_LIT if is_lit else ROOM_DARK
	style.border_color = ROOM_LIT_EDGE
	style.set_border_width_all(3 if is_lit else 0)
	return style


func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)


# wrap = true only for labels with a fixed width (inside a panel or the page).
# In a row (HBoxContainer) a wrapping label gets squeezed to 1 pixel width
# and breaks after every letter (bug from manual test 1).
func _label(parent: Node, text: String, size: int, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _box(fill: Color, border: Color, margin := 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(margin)
	return style
