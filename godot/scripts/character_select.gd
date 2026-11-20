# Character selection (spec 18): every player picks one of three figures (list on the left),
# sees it big in the middle, changes its accessory (arrows at head height: bow, red nose, antlers, spec 27)
# and its scarf/jacket colour (arrows at hip height), then presses "Next". The host decides (game_rules.gd -> character_rules.gd); this script
# only shows net.game and sends actions. When all three are ready the game starts and
# main.gd switches the screen.
# Started alone (⌘ R) there is no network: one switch plays all three players locally.
extends Control

const Settings = preload("res://scripts/settings.gd")
const CharacterRules = preload("res://scripts/rules/character_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")
const Title = preload("res://scripts/title.gd")

const IMAGES := "res://assets/images/"
const STAGE_SIZE := Vector2(1376, 768)  # the size of the house picture (ui_title.webp)
const CREAM := Color("efe2c8")
const BLOOD_RED := Color("8b1a1a")
const NIGHT := Color("0b0d14")
const GOLD := Color("d4af37")
const FIGURE_BOX := Vector2(290, 380)   # the big figure; the arrows stand beside it
const ARROW_SIZE := Vector2(64, 64)
const ACCESSORY_ROW_Y := 40.0           # head height inside the figure area
const COLOUR_ROW_Y := 235.0             # hip height
const ARROW_GAP := 40.0
const LABELS_HEIGHT := 64.0             # "Accessory: ..." and "Colour: ..." under the figure

var net: Node = null  # main.gd hands this in; started alone, it stays null

var current_player := 0  # online: my_index; offline: the switch

var _local_game := CharacterRules.new_selection_game()  # offline only
var _stage: Control
var _cards := {}       # character id -> its card button (left list)
var _thumbs := {}      # character id -> its small picture
var _owners := {}      # character id -> "Player 2" label
var _big: TextureRect  # the chosen figure, big
var _next_button: Button
var _wait_label: Label
var _message_label: Label
var _colour_prev: Button
var _colour_next: Button
var _accessory_prev: Button
var _accessory_next: Button
var _colour_label: Label     # "Colour: Green" under the figure (spec 18)
var _accessory_label: Label  # "Accessory: Bow"
var _player_buttons: Array[Button] = []


func _ready() -> void:
	if _online():
		current_player = net.my_index
		net.game_changed.connect(_refresh)
	_build_ui()
	resized.connect(_fit_stage)
	_fit_stage()
	_refresh()


func _online() -> bool:
	return net != null and net.connected and not net.game.is_empty()


# The shared game online, our own little game offline.
func _game() -> Dictionary:
	return net.game if _online() else _local_game


# The choices so far: {player: {character, colour, ready}}.
func selection() -> Dictionary:
	return _game().get("selection", {})


# ---------- reacting to clicks ----------

func _send(action: String, data: Dictionary) -> void:
	if _online():
		net.send_action(action, data)
	else:
		GameRules.apply(_local_game, current_player, action, data)
		_refresh()


func _on_card_pressed(character: String) -> void:
	var mine := _mine()
	_pick(character, mine.get("colour", CharacterRules.first_free_colour(selection(), current_player)), mine.get("accessory", "none"))


func _on_colour_arrow_pressed(direction: int) -> void:
	var mine := _mine()
	if mine.is_empty():
		return
	_pick(mine["character"], CharacterRules.next_colour(selection(), current_player, direction), mine["accessory"])


func _on_accessory_arrow_pressed(direction: int) -> void:
	var mine := _mine()
	if mine.is_empty():
		return
	_pick(mine["character"], mine["colour"], CharacterRules.next_accessory(mine["accessory"], direction))


func _pick(character: String, colour: String, accessory: String) -> void:
	_send("pick_character", {"character": character, "colour": colour, "accessory": accessory})


func _mine() -> Dictionary:
	return selection().get(current_player, {})


func _on_next_pressed() -> void:
	_send("ready", {})


func _on_player_pressed(player: int) -> void:
	current_player = player
	_refresh()


# ---------- showing the game ----------

func _refresh() -> void:
	var chosen := selection()
	if not chosen.has(current_player) and not _game().get("selection") == null:
		_pick_first_free()  # everybody always has a figure on screen; the player only changes it
		return
	var mine := _mine()
	for character in CharacterRules.character_ids():
		var holder := CharacterRules.owner_of(chosen, "character", character)
		var card: Button = _cards[character]
		card.disabled = holder != -1 and holder != current_player
		card.button_pressed = holder == current_player
		var colour: String = chosen[holder]["colour"] if holder != -1 else "red"
		var accessory: String = chosen[holder].get("accessory", "none") if holder != -1 else "none"
		_thumbs[character].texture = load(IMAGES + CharacterRules.picture_file(character, colour, accessory))
		var owner_label: Label = _owners[character]
		owner_label.text = ""
		if holder != -1:
			owner_label.text = "Player %d%s" % [holder + 1, " (you)" if holder == current_player else ""]
			if chosen[holder]["ready"]:
				owner_label.text += " - ready"
	if not mine.is_empty():
		_big.texture = load(IMAGES + CharacterRules.picture_file(mine["character"], mine["colour"], mine.get("accessory", "none")))
		_colour_label.text = "Colour: " + _name_of(Settings.CHARACTER_COLOURS, mine["colour"])
		_accessory_label.text = "Accessory: " + _name_of(Settings.ACCESSORIES, mine["accessory"])
	var is_ready: bool = not mine.is_empty() and mine["ready"]
	for arrow in [_colour_prev, _colour_next, _accessory_prev, _accessory_next]:
		arrow.disabled = mine.is_empty() or is_ready
	_next_button.disabled = mine.is_empty() or is_ready
	_wait_label.visible = is_ready
	_message_label.text = _game().get("last_event", "")
	for index in _player_buttons.size():
		_player_buttons[index].button_pressed = index == current_player


# The first character and colour nobody has: where a player starts.
func _pick_first_free() -> void:
	var chosen := selection()
	for character in CharacterRules.character_ids():
		if CharacterRules.owner_of(chosen, "character", character, current_player) == -1:
			_pick(character, CharacterRules.first_free_colour(chosen, current_player), "none")
			return


func _name_of(list: Array, id: String) -> String:
	for info in list:
		if info["id"] == id:
			return info["name"]
	return id


func _fit_stage() -> void:
	if _stage == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := maxf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	_stage.scale = Vector2(factor, factor)
	_stage.position = (size - STAGE_SIZE * factor) / 2.0


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var night := ColorRect.new()
	night.color = NIGHT
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(night)

	_stage = Control.new()  # the house in the snow, like on the title screen
	_stage.name = "Stage"
	_stage.size = STAGE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(IMAGES + "ui_title.webp")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = STAGE_SIZE
	_stage.add_child(background)
	_stage.add_child(Title.make_snow(STAGE_SIZE.x))

	var vignette := TextureRect.new()  # dark edges, and a darker middle so the cards read well
	vignette.name = "Vignette"
	vignette.texture = Title.radial(Color(NIGHT, 0.55), Color(NIGHT, 0.9), 0.35)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 24
	page.offset_right = -24
	page.add_theme_constant_override("separation", 10)
	add_child(page)

	var top_space := Control.new()
	top_space.custom_minimum_size = Vector2(0, 10)
	page.add_child(top_space)

	var title := Label.new()
	title.name = "SelectTitle"
	title.text = "Choose your character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_outline_color", NIGHT)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", BLOOD_RED)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	page.add_child(title)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(middle)

	var list := VBoxContainer.new()  # the three figures, one below the other, on the left
	list.name = "CharacterList"
	list.add_theme_constant_override("separation", 14)
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(list)
	for info in Settings.CHARACTERS:
		list.add_child(_build_card(info))

	var figure_area := CenterContainer.new()  # the big figure: in the middle of the rest, so a little right
	figure_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(figure_area)
	figure_area.add_child(_build_figure_area())

	_message_label = Label.new()
	_message_label.name = "MessageLabel"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_color_override("font_color", Color("ffd76a"))
	_message_label.custom_minimum_size = Vector2(0, 28)
	page.add_child(_message_label)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 20)
	page.add_child(bottom)
	if not _online():
		bottom.add_child(_build_player_switch())  # offline only: play all three players
	_wait_label = Label.new()
	_wait_label.name = "WaitLabel"
	_wait_label.text = "Waiting for the others ..."
	_wait_label.add_theme_color_override("font_color", Color("ffd76a"))
	_wait_label.visible = false
	bottom.add_child(_wait_label)
	_next_button = Button.new()
	_next_button.name = "NextButton"
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(240, 58)
	_next_button.add_theme_font_size_override("font_size", 28)
	_paint(_next_button, Color("2f7d3a"))
	_next_button.pressed.connect(_on_next_pressed)
	bottom.add_child(_next_button)

	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 24)
	page.add_child(bottom_space)


# The big figure with the two pairs of arrows beside it: accessories at head height,
# colour at hip height.
func _build_figure_area() -> Control:
	var area := Control.new()
	area.name = "FigureArea"
	area.custom_minimum_size = FIGURE_BOX + Vector2((ARROW_SIZE.x + ARROW_GAP) * 2 + 40, LABELS_HEIGHT)
	var middle_x := area.custom_minimum_size.x / 2.0

	_big = TextureRect.new()
	_big.name = "Picture_big"
	_big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big.size = FIGURE_BOX
	_big.position = Vector2(middle_x - FIGURE_BOX.x / 2.0, 0)
	area.add_child(_big)

	_accessory_prev = _build_arrow("AccessoryPrev", "<", -1, _on_accessory_arrow_pressed)
	_accessory_next = _build_arrow("AccessoryNext", ">", 1, _on_accessory_arrow_pressed)
	_colour_prev = _build_arrow("ColourPrev", "<", -1, _on_colour_arrow_pressed)
	_colour_next = _build_arrow("ColourNext", ">", 1, _on_colour_arrow_pressed)
	var side := FIGURE_BOX.x / 2.0 + ARROW_GAP
	_place_arrow(area, _accessory_prev, Vector2(middle_x - side - ARROW_SIZE.x, ACCESSORY_ROW_Y))
	_place_arrow(area, _accessory_next, Vector2(middle_x + side, ACCESSORY_ROW_Y))
	_place_arrow(area, _colour_prev, Vector2(middle_x - side - ARROW_SIZE.x, COLOUR_ROW_Y))
	_place_arrow(area, _colour_next, Vector2(middle_x + side, COLOUR_ROW_Y))

	# What the arrows chose, under the figure.
	_accessory_label = _build_choice_label("AccessoryLabel", area, FIGURE_BOX.y + 4)
	_colour_label = _build_choice_label("ColourLabel", area, FIGURE_BOX.y + 32)

	return area


func _build_choice_label(node_name: String, area: Control, y: float) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = Vector2(0, y)
	label.size = Vector2(area.custom_minimum_size.x, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", NIGHT)
	label.add_theme_constant_override("outline_size", 6)
	area.add_child(label)
	return label


func _build_arrow(node_name: String, text: String, direction: int, handler: Callable) -> Button:
	var arrow := Button.new()
	arrow.name = node_name
	arrow.text = text
	arrow.add_theme_font_size_override("font_size", 34)
	_paint(arrow, Color(0.1, 0.07, 0.07, 0.85))
	arrow.pressed.connect(handler.bind(direction))
	return arrow


func _place_arrow(area: Control, arrow: Button, position: Vector2) -> void:
	arrow.size = ARROW_SIZE
	arrow.position = position
	area.add_child(arrow)


# One figure in the list on the left: small picture, name and who has it.
func _build_card(info: Dictionary) -> Button:
	var id: String = info["id"]
	var card := Button.new()
	card.name = "Card_" + id
	card.toggle_mode = true
	card.custom_minimum_size = Vector2(210, 120)
	_paint(card, Color(0.1, 0.07, 0.07, 0.85))
	card.pressed.connect(_on_card_pressed.bind(id))
	_cards[id] = card

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.offset_top = 6
	row.offset_bottom = -6
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var picture := TextureRect.new()
	picture.name = "Picture_" + id
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(80, 0)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	_thumbs[id] = picture

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var name_label := Label.new()
	name_label.text = info["name"]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", CREAM)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(name_label)
	var owner_label := Label.new()
	owner_label.name = "Owner_" + id
	owner_label.add_theme_font_size_override("font_size", 14)
	owner_label.add_theme_color_override("font_color", GOLD)
	owner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(owner_label)
	_owners[id] = owner_label
	return card


func _build_player_switch() -> Control:
	var row := HBoxContainer.new()
	row.name = "PlayerSwitch"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for player in Settings.MAX_PLAYERS:
		var button := Button.new()
		button.name = "Player%dButton" % (player + 1)
		button.text = "Player %d" % (player + 1)
		button.toggle_mode = true
		button.pressed.connect(_on_player_pressed.bind(player))
		row.add_child(button)
		_player_buttons.append(button)
	return row


# A button in its own colour: lighter on hover, a gold frame while it is the chosen one.
func _paint(button: Button, colour: Color) -> void:
	var looks := {"normal": colour, "hover": colour.lightened(0.15), "pressed": colour, "hover_pressed": colour.lightened(0.15),
		"disabled": Color(colour, 0.35), "focus": colour}
	for state in looks:
		var box := StyleBoxFlat.new()
		box.bg_color = looks[state]
		box.set_corner_radius_all(8)
		box.set_content_margin_all(8)
		if state in ["pressed", "hover_pressed"]:
			box.border_color = GOLD
			box.set_border_width_all(4)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
