# The hall (spec 02): house plan with legend and room lamps, fuse box, fuse panel.
# Offline (no net, spec 02): one screen, the player buttons switch whose view we see.
# Online (main.gd hands in a net with a game, spec 04): this device shows only
# its own player; clicks go to the host, and the shared game comes back.
# The rules live in fuse_rules.gd. This script only shows them and reacts to clicks.
extends Control

const Rules = preload("res://scripts/rules/fuse_rules.gd")
const Settings = preload("res://scripts/settings.gd")

const UI_COLOURS := {
	"blue": Color("2f6fd6"), "yellow": Color("e8c62e"), "white": Color("f2f2f2"), "black": Color("1e1e1e"),
	"red": Color("d0473c"), "green": Color("4caf50"), "gold": Color("d4af37"),
}
const LAMP_ON := Color("ffd76a")
const LAMP_OFF := Color("7a6a6a")
const ROOM_DARK := Color("2b2424")  # house plan tile, fuse off (spec 05)
const ROOM_LIT := Color("f3c66b")   # house plan tile, fuse on
const ROOM_TEXT_ON_LIT := Color("3b2210")

# -1 means: a new random puzzle at every start. Tests set a fixed seed.
@export var seed_value := -1
var net: Node = null  # set by main.gd for online play

var puzzle: Dictionary
var current_player := 0
var chosen: Array = []
var penalty_total := 0

# Nodes we change later (built in _build_ui)
var _legend_label: Label
var _lamps: Array[Label] = []
var _tiles: Array[PanelContainer] = []
var _lit_before: Array[bool] = [false, false, false]
var _flicker: ColorRect        # dark overlay that flickers (spec 05)
var _flicker_timer: Timer
var _flicker_rng := RandomNumberGenerator.new()
var _player_buttons: Array[Button] = []
var _penalty_label: Label
var _fuse_panel: PanelContainer
var _fuse_title: Label
var _hint_label: Label
var _wire_buttons := {}
var _chosen_label: Label
var _message: Label


func _ready() -> void:
	if _online():
		current_player = net.my_index
		_take_game()
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
	_refresh()


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
	_message.text = net.game["last_event"]
	_refresh()


# ---------- reacting to clicks ----------

func _on_fuse_box_pressed() -> void:
	_fuse_panel.visible = true
	_refresh()


func _on_player_pressed(player: int) -> void:
	current_player = player
	chosen.clear()
	_message.text = ""
	_refresh()


func _on_wire_pressed(colour: String) -> void:
	chosen.append(colour)
	if chosen.size() == Settings.WIRE_COLOURS.size():
		_submit_attempt()
	_refresh()


func _on_reset_pressed() -> void:
	chosen.clear()
	_refresh()


# 4 wires chosen: ask the rules, then show the result.
func _submit_attempt() -> void:
	if _online():
		net.send_action("try_fuse", {"wires": chosen.duplicate()})  # the host decides
		chosen.clear()
		return
	var fuse: Dictionary = puzzle["fuses"][current_player]
	var result := Rules.try_fuse(puzzle, current_player, chosen)
	chosen.clear()
	if result["error"] != "":
		_message.text = result["error"]
	elif result["correct"]:
		_message.text = "The %s fuse is on! The %s is lit." % [fuse["colour"], fuse["room"]]
	else:
		penalty_total += result["penalty_seconds"]
		_message.text = "Wrong order: -%d s" % result["penalty_seconds"]


# ---------- showing the current state ----------

func _refresh() -> void:
	var legend_lines := []
	for symbol in Settings.SYMBOLS:
		legend_lines.append("%s = %s" % [symbol, puzzle["legend"][symbol]])
	_legend_label.text = "\n".join(legend_lines)

	var lit := Rules.lit_rooms(puzzle)
	for i in _lamps.size():
		var room: String = puzzle["fuses"][i]["room"]
		var is_lit := room in lit
		_lamps[i].text = "%s: %s" % [room, "lit" if is_lit else "dark"]
		_lamps[i].add_theme_color_override("font_color", ROOM_TEXT_ON_LIT if is_lit else LAMP_OFF)
		_tiles[i].add_theme_stylebox_override("panel", _box(ROOM_LIT if is_lit else ROOM_DARK, Color("3b2a26"), 8))
		if is_lit and not _lit_before[i]:
			_glow(_tiles[i])
		_lit_before[i] = is_lit
	_update_flicker(lit.size())

	for i in _player_buttons.size():
		_player_buttons[i].button_pressed = (i == current_player)
	_penalty_label.text = "Penalty: %d s" % penalty_total

	var fuse: Dictionary = puzzle["fuses"][current_player]
	_fuse_title.text = "Player %d, your fuse: %s" % [current_player + 1, fuse["colour"].to_upper()]
	_fuse_title.add_theme_color_override("font_color", UI_COLOURS[fuse["colour"]])

	var seen := _fuse_seen_by(current_player)
	var seen_colour: String = puzzle["fuses"][seen]["colour"]
	_hint_label.text = "Torn label you can see (%s fuse): %s\nRead it out to its owner!" % [
		seen_colour, ", ".join(Rules.label_for(puzzle, seen))]

	for colour in _wire_buttons:
		_wire_buttons[colour].disabled = fuse["solved"] or colour in chosen
	if fuse["solved"]:
		_chosen_label.text = "This fuse is already on."
	elif chosen.is_empty():
		_chosen_label.text = "Your order: click the wires"
	else:
		_chosen_label.text = "Your order: " + ", ".join(chosen)


# The fuse whose torn label this player can see.
func _fuse_seen_by(player: int) -> int:
	for i in Settings.FUSES.size():
		if Rules.label_viewer(i) == player:
			return i
	return -1


# ---------- atmosphere (spec 05) ----------

# How dark the flicker may get: strongest with 0 fuses on, 0 with all fuses on.
static func flicker_strength(lit_count: int) -> float:
	var total := Settings.FUSES.size()
	return Settings.FLICKER_MAX_DARKNESS * float(total - clampi(lit_count, 0, total)) / total


func flicker_active() -> bool:
	return _flicker_timer != null and not _flicker_timer.is_stopped()


func _update_flicker(lit_count: int) -> void:
	if flicker_strength(lit_count) <= 0.0:
		_flicker_timer.stop()
		_flicker.color.a = 0.0  # power is back: steady light
	elif _flicker_timer.is_stopped():
		_flicker_timer.start(0.1)


# Mostly calm, now and then the light dips. Then wait a random short time.
func _on_flicker_tick() -> void:
	var strength := flicker_strength(Rules.lit_rooms(puzzle).size())
	_flicker.color.a = _flicker_rng.randf_range(0.0, strength) if _flicker_rng.randf() < 0.6 else 0.0
	_flicker_timer.start(_flicker_rng.randf_range(0.05, 0.4))


# A room tile flashes bright for a moment when its light comes on.
func _glow(tile: Control) -> void:
	tile.modulate = Color(1.8, 1.8, 1.8)
	create_tween().tween_property(tile, "modulate", Color.WHITE, 0.8)


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var background := ColorRect.new()
	background.color = Color("1b1012")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)

	# Top bar: title, player switch, penalty
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	page.add_child(top)
	var title := _label(top, "The Hall", 34)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	for i in Settings.FUSES.size():
		var button := Button.new()
		button.name = "PlayerButton%d" % i
		button.text = "Player %d" % (i + 1)
		button.toggle_mode = true
		button.pressed.connect(_on_player_pressed.bind(i))
		top.add_child(button)
		_player_buttons.append(button)
	_penalty_label = _label(top, "", 20)
	_penalty_label.name = "PenaltyLabel"
	_penalty_label.add_theme_color_override("font_color", Color("ff8a80"))

	# Middle: house plan on the left, fuse box on the right
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 24)
	page.add_child(middle)

	var plan := _card(middle, "House plan")
	plan.get_parent().custom_minimum_size = Vector2(320, 0)
	_label(plan, "Legend", 18).add_theme_color_override("font_color", Color("c9b8a0"))
	_legend_label = _label(plan, "", 20)
	_legend_label.name = "LegendLabel"
	_label(plan, "Rooms", 18).add_theme_color_override("font_color", Color("c9b8a0"))
	for i in Settings.FUSES.size():
		var tile := PanelContainer.new()
		tile.name = "RoomTile%d" % i
		plan.add_child(tile)
		_tiles.append(tile)
		var lamp := _label(tile, "", 20)
		lamp.name = "RoomLamp%d" % i
		_lamps.append(lamp)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 16)
	middle.add_child(right)

	var fuse_box := Button.new()
	fuse_box.name = "FuseBoxButton"
	fuse_box.text = "Open the fuse box"
	fuse_box.custom_minimum_size = Vector2(0, 64)
	fuse_box.add_theme_stylebox_override("normal", _box(Color("2b2b2b"), Color("d4af37")))
	fuse_box.add_theme_stylebox_override("hover", _box(Color("3a3a3a"), Color("ffd76a")))
	fuse_box.add_theme_stylebox_override("pressed", _box(Color("222222"), Color("d4af37")))
	fuse_box.pressed.connect(_on_fuse_box_pressed)
	right.add_child(fuse_box)

	var fuse_area := _card(right, "")
	_fuse_panel = fuse_area.get_parent()
	_fuse_panel.name = "FusePanel"
	_fuse_panel.visible = false
	_fuse_title = _label(fuse_area, "", 26)
	_fuse_title.name = "FuseTitle"
	_hint_label = _label(fuse_area, "", 20, true)
	_hint_label.name = "LabelHint"
	_hint_label.add_theme_color_override("font_color", Color("c9b8a0"))

	var wires := HBoxContainer.new()
	wires.add_theme_constant_override("separation", 12)
	fuse_area.add_child(wires)
	for colour in Settings.WIRE_COLOURS:
		var wire := _wire_button(colour)
		wires.add_child(wire)
		_wire_buttons[colour] = wire

	var order_row := HBoxContainer.new()
	order_row.add_theme_constant_override("separation", 12)
	fuse_area.add_child(order_row)
	_chosen_label = _label(order_row, "", 20)
	_chosen_label.name = "ChosenLabel"
	_chosen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reset := Button.new()
	reset.name = "ResetButton"
	reset.text = "Reset"
	reset.pressed.connect(_on_reset_pressed)
	order_row.add_child(reset)

	_message = _label(page, "", 24, true)
	_message.name = "Message"
	_message.add_theme_color_override("font_color", Color("ffd76a"))

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


# wrap = true only for labels with a fixed width (inside a panel or the page).
# In a row (HBoxContainer) a wrapping label gets squeezed to 1 pixel width
# and breaks after every letter (bug from manual test 1).
func _label(parent: Node, text: String, size: int, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


# A dark panel with a border. Returns the box inside it where content goes.
func _card(parent: Node, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("2a1a17"), Color("5c2a22")))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	if heading != "":
		_label(content, heading, 24).add_theme_color_override("font_color", Color("e8d9c0"))
	return content


func _box(fill: Color, border: Color, margin := 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(margin)
	return style


func _wire_button(colour: String) -> Button:
	var button := Button.new()
	button.name = "Wire_" + colour
	button.text = colour
	button.custom_minimum_size = Vector2(110, 56)
	var fill: Color = UI_COLOURS[colour]
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _box(fill, Color("3b1f1f")))
	button.add_theme_stylebox_override("disabled", _box(fill.darkened(0.75), Color("3b1f1f")))
	var text_colour := Color.WHITE if colour in ["blue", "black"] else Color.BLACK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_colour)
	button.pressed.connect(_on_wire_pressed.bind(colour))
	return button

