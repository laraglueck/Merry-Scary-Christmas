extends Control

const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")

const IMAGES := "res://assets/images/"
const RED_FUSE := 0
const LivingRoomRules = preload("res://scripts/rules/living_room_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const RoomStage = preload("res://scripts/room_stage.gd")

@export var seed_value := -1
@export var red_fuse_on := true

var net: Node = null
var game: Dictionary
var _background: TextureRect
var _clock_panel: Panel
var _short_hand: Node2D
var _long_hand: Node2D
var _selected_hand := "short"
var _hour_position := 3
var _minute_position := 12
var _message: Label
var _gift_button: TextureButton
var _piece_button: TextureButton  # a torn piece of the photo in the open clock (spec 21)
var _digit_label: Label
var _note_panel: Panel
var _note_text: Label


func _ready() -> void:
	if net != null:
		game = net.game
		net.game_changed.connect(_on_game_changed)
	else:
		game = _offline_game()

	_background = TextureRect.new()
	_background.name = "Background"
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_build_clock_ui()
	_build_clock_controls()
	_build_clock_submission()
	_build_reward()
	_build_note_ui()
	_build_back_button()
	_refresh()
	RoomStage.put_on_stage(self)  # click areas stay on their objects when the window changes (spec 21)


func _offline_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	var local_game := GameRules.new_game(rng)
	local_game["location"] = "living_room"

	if red_fuse_on:
		var wires: Array = local_game["puzzle"]["fuses"][RED_FUSE]["order"].duplicate()
		FuseRules.try_fuse(local_game["puzzle"], RED_FUSE, wires)

	local_game["last_event"] = ""
	return local_game


func _on_game_changed() -> void:
	game = net.game
	_refresh()


func _refresh() -> void:
	if game.is_empty():
		return

	var lit: bool = game["puzzle"]["fuses"][RED_FUSE]["solved"]
	var picture := "room_living_room_lit.webp" if lit else "room_living_room_dark.webp"
	_background.texture = load(IMAGES + picture)
	_message.text = game.get("last_event", "")
	var room: Dictionary = game["living_room"]
	var solved: bool = room["solved"]

	_gift_button.visible = solved and not room["gift_taken"]
	_piece_button.visible = solved and not InventoryRules.has(game, "photo_piece_1") \
			and not InventoryRules.has(game, "photo")
	_digit_label.visible = solved
	_digit_label.text = str(room["digit"])

	if solved:
		_clock_panel.hide()


func _build_clock_ui() -> void:
	var clock_button := Button.new()
	clock_button.name = "ClockButton"
	clock_button.text = ""
	clock_button.position = Vector2(190, 130)
	clock_button.size = Vector2(140, 390)

	for state in ["normal", "hover", "pressed"]:
		clock_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	clock_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clock_button.pressed.connect(_open_clock)
	add_child(clock_button)

	var clock_label := Label.new()
	clock_label.text = ""  # spec 21: no names on the objects; the name shows on hover
	clock_button.tooltip_text = "Inspect the clock"
	clock_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clock_label.position = Vector2(0, 12)
	clock_label.size = Vector2(140, 30)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_button.add_child(clock_label)

	_clock_panel = Panel.new()
	_clock_panel.name = "ClockPanel"
	_clock_panel.position = Vector2(326, 60)
	_clock_panel.size = Vector2(500, 520)
	_clock_panel.hide()
	add_child(_clock_panel)

	var face := TextureRect.new()
	face.name = "ClockFace"
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture = load(IMAGES + "prop_clock_face.png")
	face.position = Vector2(70, 30)
	face.size = Vector2(360, 360)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_panel.add_child(face)
	
	_short_hand = _create_hand(
		"prop_clock_hand_short.png",
		125.0,
		Vector2(0.5, 0.883)
	)
	_long_hand = _create_hand(
		"prop_clock_hand_long.png",
		160.0,
		Vector2(0.5, 0.883)
	)

	_short_hand.rotation_degrees = 90.0
	_long_hand.rotation_degrees = 0.0

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(260, 455)
	close_button.size = Vector2(200, 40)
	close_button.pressed.connect(_close_clock)
	_clock_panel.add_child(close_button)




func _open_clock() -> void:
	_clock_panel.show()


func _close_clock() -> void:
	_clock_panel.hide()
func _create_hand(
	file_name: String,
	image_height: float,
	pivot_fraction: Vector2
) -> Node2D:
	var pivot := Node2D.new()
	pivot.position = Vector2(250, 210)
	_clock_panel.add_child(pivot)

	var image := Sprite2D.new()
	image.texture = load(IMAGES + file_name)
	image.centered = false

	var texture_size := image.texture.get_size()
	image.offset = -texture_size * pivot_fraction

	var factor := image_height / texture_size.y
	image.scale = Vector2(factor, factor)
	pivot.add_child(image)

	return pivot
func _build_clock_controls() -> void:
	var hand_group := ButtonGroup.new()
	var short_button := Button.new()
	short_button.text = "Short hand"
	short_button.toggle_mode = true
	short_button.button_group = hand_group
	short_button.button_pressed = true
	short_button.position = Vector2(40, 400)
	short_button.size = Vector2(200, 35)
	short_button.pressed.connect(_select_hand.bind("short"))
	_clock_panel.add_child(short_button)

	var long_button := Button.new()
	long_button.text = "Long hand"
	long_button.toggle_mode = true
	long_button.button_group = hand_group
	long_button.position = Vector2(260, 400)
	long_button.size = Vector2(200, 35)
	long_button.pressed.connect(_select_hand.bind("long"))
	_clock_panel.add_child(long_button)

	for number in range(1, 13):
		var angle := deg_to_rad(number * 30.0 - 90.0)
		var direction := Vector2(cos(angle), sin(angle))

		var button := Button.new()
		button.text = str(number)
		button.position = Vector2(250, 210) + direction * 125.0 - Vector2(16, 16)
		button.size = Vector2(32, 32)
		button.pressed.connect(_set_hand_position.bind(number))
		_clock_panel.add_child(button)


func _select_hand(hand: String) -> void:
	_selected_hand = hand


func _set_hand_position(number: int) -> void:
	if _selected_hand == "short":
		_hour_position = number
	else:
		_minute_position = number

	_short_hand.rotation_degrees = (_hour_position % 12) * 30.0
	_long_hand.rotation_degrees = (_minute_position % 12) * 30.0
func _build_clock_submission() -> void:
	var try_button := Button.new()
	try_button.name = "TryClockButton"
	try_button.text = "Try clock"
	try_button.position = Vector2(40, 455)
	try_button.size = Vector2(200, 40)
	try_button.pressed.connect(_try_clock)
	_clock_panel.add_child(try_button)

	_message = Label.new()
	_message.name = "Message"
	_message.position = Vector2(24, 596)
	_message.size = Vector2(1100, 40)
	_message.add_theme_font_size_override("font_size", 20)
	_message.add_theme_color_override("font_color", Color("ffd76a"))
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 5)
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message)


func _try_clock() -> void:
	_send("set_clock", {
		"hour": _hour_position,
		"minute": _minute_position,
	})


func _send(action: String, data: Dictionary) -> void:
	if net != null:
		net.send_action(action, data)
	else:
		GameRules.apply(game, 0, action, data)
		_refresh()
func _build_reward() -> void:
	_gift_button = TextureButton.new()
	_gift_button.name = "GiftButton"
	_gift_button.texture_normal = load(IMAGES + "item_gift_1.png")
	_gift_button.ignore_texture_size = true
	_gift_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_gift_button.position = Vector2(205, 420)
	_gift_button.size = Vector2(90, 90)
	_gift_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_gift_button.tooltip_text = "Take present"
	_gift_button.pressed.connect(_take_gift)
	add_child(_gift_button)

	# Spec 21: a torn piece of the photo, tucked into the open clock case.
	_piece_button = TextureButton.new()
	_piece_button.name = "PhotoPiece"
	_piece_button.texture_normal = load(IMAGES + "item_photo_piece_1.png")
	_piece_button.ignore_texture_size = true
	_piece_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_piece_button.position = Vector2(250, 300)
	_piece_button.size = Vector2(70, 70)
	_piece_button.rotation_degrees = 10
	_piece_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_piece_button.tooltip_text = "A torn piece of paper"
	_piece_button.pressed.connect(func() -> void: _send("take_piece", {"room": "living_room"}))
	add_child(_piece_button)

	_digit_label = Label.new()
	_digit_label.name = "DigitLabel"
	_digit_label.position = Vector2(230, 375)
	_digit_label.add_theme_font_size_override("font_size", 32)
	_digit_label.add_theme_color_override("font_color", Color("ff7777"))
	_digit_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_digit_label.add_theme_constant_override("outline_size", 5)
	_digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_digit_label)


func _take_gift() -> void:
	_send("take_gift", {"room": "living_room"})
func _build_note_ui() -> void:
	var note_button := Button.new()
	note_button.name = "NoteButton"
	note_button.text = ""  # spec 21: no names on the objects; the name shows on hover
	note_button.tooltip_text = "Read the note"
	note_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	note_button.position = Vector2(1000, 260)
	note_button.size = Vector2(130, 120)
	note_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	for state in ["normal", "hover", "pressed"]:
		note_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	note_button.pressed.connect(_open_note)
	add_child(note_button)

	_note_panel = Panel.new()
	_note_panel.name = "NotePanel"
	_note_panel.position = Vector2(326, 60)
	_note_panel.size = Vector2(500, 520)
	_note_panel.hide()
	add_child(_note_panel)

	var paper := TextureRect.new()
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.texture = load(IMAGES + "prop_note.png")
	paper.size = Vector2(500, 440)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_panel.add_child(paper)

	_note_text = Label.new()
	_note_text.position = Vector2(55, 90)
	_note_text.size = Vector2(390, 300)
	_note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_text.add_theme_font_size_override("font_size", 22)
	_note_text.add_theme_color_override("font_color", Color("302016"))
	_note_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_panel.add_child(_note_text)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(185, 455)
	close_button.size = Vector2(130, 40)
	close_button.pressed.connect(_close_note)
	_note_panel.add_child(close_button)


func _open_note() -> void:
	if game.is_empty():
		return

	if not game["puzzle"]["fuses"][RED_FUSE]["solved"]:
		_message.text = "The living room is too dark to read."
		return

	var lines := LivingRoomRules.rhyme_for(game["bathroom"]["tap_order"])
	_note_text.text = "\n\n".join(lines)
	_clock_panel.hide()
	_note_panel.get_parent().move_child(_note_panel, -1)  # on top (it lives on the stage, spec 21)
	_note_panel.show()


func _close_note() -> void:
	_note_panel.hide()


# The way back: the whole team walks to the hall (spec 07), like in the other rooms.
func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back to the hall"
	back.position = Vector2(940, 16)
	back.add_theme_font_size_override("font_size", 20)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.07, 0.07, 0.85)
	box.border_color = Color("5c4a3a")
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(12)
	back.add_theme_stylebox_override("normal", box)
	back.pressed.connect(func() -> void: _send("go_to", {"place": "hall"}))
	add_child(back)

