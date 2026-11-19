extends Control

const GameRules = preload("res://scripts/rules/game_rules.gd")
const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const IMAGES := "res://assets/images/"
const BACKGROUND_DARK = preload(IMAGES + "room_bedroom_dark.webp")
const BACKGROUND_LIT = preload(IMAGES + "room_bedroom_lit.webp")
const CALENDAR_CLOSED = preload(IMAGES + "prop_calendar_closed.png")
const CALENDAR_OPEN = preload(IMAGES + "prop_calendar_open.png")
const SHORT_HAND = preload(IMAGES + "prop_clock_hand_short.png")
const LONG_HAND = preload(IMAGES + "prop_clock_hand_long.png")
const WHEEL_ART = preload(IMAGES + "prop_wheel.png")
const SYMBOL_ART := {
	"star": preload(IMAGES + "sym_star.png"),
	"bell": preload(IMAGES + "sym_bell.png"),
	"tree": preload(IMAGES + "sym_tree.png"),
	"snowflake": preload(IMAGES + "sym_snowflake.png"),
}
const GIFT_ART = preload(IMAGES + "item_gift_3.png")
const PHOTO_ART = preload(IMAGES + "item_photo.png")
const CHEST_OPEN_SOUND = preload("res://assets/sounds/sfx_creak.mp3")
const GIFT_SOUND = preload("res://assets/sounds/sfx_gift.mp3")

# Bounds measured in the screenshot's 1152 × 648 game viewport.
const CALENDAR_BOUNDS := Rect2(0.347, 0.204, 0.181, 0.296)
const CHEST_BOUNDS := Rect2(0.746, 0.688, 0.239, 0.285)
const GOLD := Color("#e8c18c")
const TEXT := Color("#f4e7d1")

@export var seed_value := -1

var net: Node
var offline_game: Dictionary
var room_view: Control
var background_rect: TextureRect
var modal: CenterContainer
var popup_panel: PanelContainer
var popup_title: Label
var popup_description: Label
var status_label: Label
var digit_label: Label
var wheel_row: HBoxContainer
var wheel_symbols: Array[TextureRect] = []
var calendar_grid: GridContainer
var clue_picture: TextureRect
var photo_picture: TextureRect
var room_sound: AudioStreamPlayer
var had_room_state := false
var was_gift_taken := false
var calendar_doors: Array[Button] = []
var close_button: Button
var back_button: Button
var popup_opener: Button
var current_popup := ""
var inspected_door := 0
var bedroom_is_lit := false
var shared_selection: Array = []
var was_solved := false

@onready var old_ui: VBoxContainer = $VBoxContainer
@onready var chest_button: Button = $VBoxContainer/ToyChestButton
@onready var gift_button: Button = $VBoxContainer/GiftButton
@onready var photo_button: Button = $VBoxContainer/PhotoButton
@onready var wheels: Array[OptionButton] = [
	$VBoxContainer/Wheel1, $VBoxContainer/Wheel2, $VBoxContainer/Wheel3,
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_room()
	_build_popup()
	room_sound = AudioStreamPlayer.new()
	room_sound.volume_db = -14.0
	add_child(room_sound)
	old_ui.hide()
	resized.connect(_layout)
	_layout()
	if is_instance_valid(net):
		net.game_changed.connect(_update_room)
	else:
		offline_game = _new_offline_game()
	_update_room()


func _build_room() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#1b1012")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	room_view = Control.new()
	room_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(room_view)

	background_rect = TextureRect.new()
	background_rect.texture = BACKGROUND_DARK
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_view.add_child(background_rect)
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.text = "The Bedroom"
	title.position = Vector2(24, 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#e8d9c0"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	room_view.add_child(title)

	_add_hotspot("CalendarHotspot", "Examine Advent Calendar", CALENDAR_BOUNDS, "calendar")
	_add_hotspot("ChestHotspot", "Examine Toy Chest", CHEST_BOUNDS, "chest")

	back_button = Button.new()
	back_button.text = "Back to the Hall"
	_style_button(back_button)
	room_view.add_child(back_button)
	_anchor_to_bounds(back_button, Rect2(0.02, 0.88, 0.21, 0.09))
	back_button.pressed.connect(func(): _send("go_to", {"place": "hall"}))


func _layout() -> void:
	var artwork := BACKGROUND_DARK.get_size()
	var scale_factor := minf(size.x / artwork.x, size.y / artwork.y)
	room_view.size = artwork * scale_factor
	room_view.position = (size - room_view.size) * 0.5
	popup_panel.custom_minimum_size.x = clampf(size.x - 24.0, 260.0, 470.0)


func _add_hotspot(node_name: String, hint: String, bounds: Rect2, page: String) -> void:
	var button := Button.new()
	button.name = node_name
	button.tooltip_text = hint
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var outline := _box(Color.TRANSPARENT, Color("#d4a35b"), 2, 10, 0)
	outline.draw_center = false
	for state in ["hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, outline)
	room_view.add_child(button)
	_anchor_to_bounds(button, bounds)
	button.pressed.connect(func():
		popup_opener = button
		_open_popup(page)
	)


func _anchor_to_bounds(control: Control, bounds: Rect2) -> void:
	control.set_anchor_and_offset(SIDE_RIGHT, bounds.end.x, 0.0)
	control.set_anchor_and_offset(SIDE_BOTTOM, bounds.end.y, 0.0)
	control.set_anchor_and_offset(SIDE_LEFT, bounds.position.x, 0.0)
	control.set_anchor_and_offset(SIDE_TOP, bounds.position.y, 0.0)


func _build_popup() -> void:
	modal = CenterContainer.new()
	modal.hide()
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	move_child(backdrop, modal.get_index())
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.hide()
	modal.visibility_changed.connect(func(): backdrop.visible = modal.visible)

	popup_panel = PanelContainer.new()
	popup_panel.add_theme_stylebox_override(
		"panel", _box(Color("#211915"), Color("#b58a50"), 3, 10, 16)
	)
	modal.add_child(popup_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	popup_panel.add_child(content)

	popup_title = _add_label(content, 24, GOLD)
	popup_description = _add_label(content, 16, TEXT)

	wheel_row = HBoxContainer.new()
	wheel_row.add_theme_constant_override("separation", 8)
	content.add_child(wheel_row)
	for i in wheels.size():
		var wheel := wheels[i]
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wheel_row.add_child(column)
		var dial := _add_picture(column, WHEEL_ART, 76)
		var symbol_picture := _add_picture(dial, null, 0)
		symbol_picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		symbol_picture.offset_left = -19
		symbol_picture.offset_top = -19
		symbol_picture.offset_right = 19
		symbol_picture.offset_bottom = 19
		wheel_symbols.append(symbol_picture)

		wheel.reparent(column, false)
		wheel.clear()
		for symbol in BedroomRules.SYMBOLS:
			wheel.add_item(symbol.capitalize())
		_style_button(wheel)
		wheel.item_selected.connect(_update_wheel_symbol.bind(i))
		_update_wheel_symbol(wheel.selected, i)

	for button in [chest_button, gift_button]:
		button.reparent(content, false)
		_style_button(button)
	gift_button.icon = GIFT_ART
	gift_button.add_theme_constant_override("icon_max_width", 56)
	gift_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_button.pressed.connect(_submit_wheels)
	gift_button.pressed.connect(func(): _send("take_gift", {"room": "bedroom"}))

	calendar_grid = GridContainer.new()
	calendar_grid.columns = 4
	content.add_child(calendar_grid)
	for door in range(1, 13):
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_constant_override("icon_max_width", 28)
		_style_button(button)
		calendar_grid.add_child(button)
		calendar_doors.append(button)
		button.pressed.connect(_inspect_door.bind(door))

	clue_picture = _add_picture(content, null, 64)
	photo_picture = _add_picture(content, PHOTO_ART, 168)

	photo_button.reparent(content, false)
	_style_button(photo_button)
	photo_button.pressed.connect(func(): _send("take_photo"))

	status_label = _add_label(content, 16, TEXT)
	digit_label = _add_label(content, 24, GOLD)

	close_button = Button.new()
	_style_button(close_button)
	content.add_child(close_button)
	close_button.pressed.connect(_leave_popup)


func _add_picture(parent: Control, texture: Texture2D, height: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.custom_minimum_size.y = height
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture


func _update_wheel_symbol(index: int, wheel_index: int) -> void:
	wheel_symbols[wheel_index].texture = SYMBOL_ART[BedroomRules.SYMBOLS[index]]


func _add_label(parent: Control, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


func _style_button(button: Button) -> void:
	var border := Color("#a17a4c")
	button.add_theme_stylebox_override("normal", _box(Color("#79483f"), border, 1, 8, 6))
	button.add_theme_stylebox_override("hover", _box(Color("#995b4e"), GOLD, 1, 8, 6))
	button.add_theme_stylebox_override("pressed", _box(Color("#58352f"), GOLD, 1, 8, 6))
	button.add_theme_stylebox_override("disabled", _box(Color("#30272a"), border, 1, 8, 6))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color("#ad9d91"))
	button.custom_minimum_size.y = 34


func _box(fill: Color, border: Color, width: int, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style


func _open_popup(page: String) -> void:
	current_popup = page
	if page == "calendar":
		inspected_door = 0
	modal.show()
	_update_room()
	close_button.grab_focus()


func _leave_popup() -> void:
	if current_popup == "photo":
		_open_popup("calendar")
		return
	current_popup = ""
	modal.hide()
	if is_instance_valid(popup_opener):
		popup_opener.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if modal.visible and event.is_action_pressed("ui_cancel"):
		_leave_popup()
		get_viewport().set_input_as_handled()


func _inspect_door(door: int) -> void:
	var game := _game()
	var room: Dictionary = game.get("bedroom", {})
	var clue: Dictionary = game.get("living_room", {})
	inspected_door = door
	if room.get("solved", false) and door == BedroomRules.photo_door(room, clue):
		_open_popup("photo")
	else:
		_update_popup(game, room)


func _update_room() -> void:
	var game := _game()
	var puzzle: Dictionary = game.get("puzzle", {})
	var room: Dictionary = game.get("bedroom", {})
	bedroom_is_lit = puzzle.has("fuses") and "bedroom" in FuseRules.lit_rooms(puzzle)
	background_rect.texture = BACKGROUND_LIT if bedroom_is_lit else BACKGROUND_DARK
	back_button.disabled = game.is_empty()

	var solved: bool = room.get("solved", false)
	var gift_taken: bool = room.get("gift_taken", false)
	if had_room_state and DisplayServer.get_name() != "headless":
		if gift_taken and not was_gift_taken:
			room_sound.stream = GIFT_SOUND
			room_sound.play()
		elif solved and not was_solved:
			room_sound.stream = CHEST_OPEN_SOUND
			room_sound.play()
	had_room_state = not room.is_empty()
	was_gift_taken = gift_taken

	var selected: Array = room.get("selected_wheels", [])
	# Clock updates and unrelated actions must leave an unsubmitted selection alone.
	if selected != shared_selection or (solved and not was_solved):
		shared_selection = selected.duplicate()
		if selected.size() == wheels.size():
			for i in wheels.size():
				var index := BedroomRules.SYMBOLS.find(selected[i])
				if index >= 0:
					wheels[i].select(index)
					_update_wheel_symbol(index, i)
	was_solved = solved

	if modal.visible:
		_update_popup(game, room)


func _update_popup(game: Dictionary, room: Dictionary) -> void:
	var solved: bool = room.get("solved", false)
	var gift_taken: bool = room.get("gift_taken", false)
	var photo_taken: bool = room.get("photo_taken", false)
	var interactive := bedroom_is_lit and not room.is_empty()

	var chest := current_popup == "chest"
	var calendar := current_popup == "calendar"
	var photo := current_popup == "photo"
	wheel_row.visible = chest and interactive and not solved
	photo_picture.visible = photo and interactive and solved and not photo_taken
	clue_picture.hide()
	chest_button.visible = chest and interactive and not solved
	gift_button.visible = chest and interactive and solved and not gift_taken
	photo_button.visible = photo and interactive and solved and not photo_taken
	calendar_grid.visible = calendar and interactive
	digit_label.visible = chest and interactive and solved
	close_button.text = "Back to Calendar" if photo else "Close"

	popup_title.text = {"chest": "THE TOY CHEST", "calendar": "ADVENT CALENDAR", "photo": "OLD PHOTOGRAPH"}[current_popup]
	popup_description.text = ""
	status_label.text = ""
	if not interactive:
		status_label.text = "No active game." if game.is_empty() else "The room is too dark. Restore power with the gold fuse."
	else:
		match current_popup:
			"chest":
				popup_description.text = "The toy chest is open." if solved else "Three symbols guard the chest. Look for the combination elsewhere in the house."
				digit_label.text = "GOLDEN DIGIT: %s" % BedroomRules.gold_digit(room)
				if gift_taken:
					status_label.text = "The present has been collected."
				elif not solved and "wrong symbols" in str(game.get("last_event", "")):
					status_label.text = str(game["last_event"])
			"calendar":
				_update_calendar(game.get("living_room", {}), solved)
			"photo":
				popup_description.text = "An old photograph shows Santa and Scary Jingles together."
				if photo_taken:
					status_label.text = "The photograph has been collected."
	status_label.visible = not status_label.text.is_empty()
	popup_description.visible = not popup_description.text.is_empty()


func _update_calendar(clue: Dictionary, solved: bool) -> void:
	var hour := int(clue.get("hour", 0))
	var minute := int(clue.get("minute", 0))
	for i in calendar_doors.size():
		var door := i + 1
		var button := calendar_doors[i]
		button.text = str(door)
		var is_clue := door == hour or door == minute
		button.disabled = not solved and not is_clue
		button.icon = CALENDAR_OPEN if is_clue or door == inspected_door else CALENDAR_CLOSED
		button.tooltip_text = "Short hand" if door == hour else ("Long hand" if door == minute else "")

	popup_description.text = "The open doors show where the clock hands point."
	if inspected_door == hour and hour > 0:
		clue_picture.texture = SHORT_HAND
		clue_picture.show()
		status_label.text = "The short hand points to %d." % hour
	elif inspected_door == minute and minute > 0:
		clue_picture.texture = LONG_HAND
		clue_picture.show()
		status_label.text = "The long hand points to %d." % minute
	elif inspected_door > 0:
		status_label.text = "Door %d is empty." % inspected_door


func _submit_wheels() -> void:
	var symbols: Array = []
	for wheel in wheels:
		if wheel.selected < 0:
			return
		symbols.append(BedroomRules.SYMBOLS[wheel.selected])
	_send("set_wheels", {"symbols": symbols})


func _new_offline_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var game := GameRules.new_game(rng)
	game["location"] = "bedroom"
	for fuse in game["puzzle"]["fuses"]:
		if fuse["room"] == "bedroom":
			fuse["solved"] = true
			break
	return game


func _game() -> Dictionary:
	return net.game if is_instance_valid(net) else offline_game


func _send(action: String, data: Dictionary = {}) -> void:
	if _game().is_empty():
		return
	if is_instance_valid(net):
		net.send_action(action, data)
	else:
		GameRules.apply(offline_game, 0, action, data)
		if offline_game["location"] == "hall" and get_tree().current_scene == self:
			get_tree().change_scene_to_file("res://scenes/hall.tscn")
		else:
			_update_room()
