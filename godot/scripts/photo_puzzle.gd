# The photo puzzle (spec 21): the three torn pieces lie side by side in a jumbled
# order. Clicking one piece and then another swaps them. When the torn edges fit
# (left, middle, right), the window asks the host to put the photo together
# (action "assemble_photo"), and the whole photo shows.
# main.gd opens it over the game when a piece in the inventory is clicked.
extends Control

const IMAGES := "res://assets/images/"
const PIECES := ["photo_piece_1", "photo_piece_2", "photo_piece_3"]  # the right order
const START := ["photo_piece_3", "photo_piece_1", "photo_piece_2"]   # jumbled
const HIGHLIGHT := Color("ffd76a")
const PIECE_SIZE := Vector2(170, 165)

var net: Node = null  # set by main.gd; actions go to the host

var _order: Array = START.duplicate()
var _picked := -1          # the first piece clicked, waiting for the second
var _done := false
var _buttons: Array[TextureButton] = []
var _frames: Array[PanelContainer] = []  # a gold frame around the piece that was picked
var _whole: TextureRect
var _hint: Label


func _ready() -> void:
	_build_ui()
	_refresh()


# The pieces left to right as they lie now (for tests too).
func order() -> Array:
	return _order.duplicate()


func _on_piece_pressed(slot: int) -> void:
	if _done:
		return
	if _picked == -1:
		_picked = slot
	elif _picked == slot:
		_picked = -1  # clicked twice: put it back down
	else:
		var other: String = _order[_picked]
		_order[_picked] = _order[slot]
		_order[slot] = other
		_picked = -1
		if _order == PIECES:
			_done = true
			if net != null:
				net.send_action("assemble_photo", {"order": _order.duplicate()})
	_refresh()


func _refresh() -> void:
	for slot in _buttons.size():
		var button := _buttons[slot]
		button.texture_normal = load(IMAGES + "item_photo_piece_%s.png" % _order[slot].trim_prefix("photo_piece_"))
		_frames[slot].add_theme_stylebox_override("panel", _frame_style(slot == _picked))
		_frames[slot].visible = not _done
	_whole.visible = _done
	_hint.text = "The photo is whole again: Santa and a young, laughing Jingles." if _done \
			else "Click two pieces to swap them, until the torn edges fit."


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "PuzzlePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("2a1d17")
	box_style.border_color = Color("8a6a3a")
	box_style.set_border_width_all(4)
	box_style.set_corner_radius_all(14)
	box_style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", box_style)
	add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "A torn photograph"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	content.add_child(title)

	var table := Control.new()  # the pieces, or the whole photo once they fit
	table.custom_minimum_size = Vector2(PIECE_SIZE.x * 3 + 24, PIECE_SIZE.y)
	content.add_child(table)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	table.add_child(row)
	for slot in 3:
		var frame := PanelContainer.new()
		frame.name = "PuzzleFrame%d" % slot
		row.add_child(frame)
		_frames.append(frame)
		var button := TextureButton.new()
		button.name = "PuzzlePiece%d" % slot
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = PIECE_SIZE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_piece_pressed.bind(slot))
		frame.add_child(button)
		_buttons.append(button)
	_whole = TextureRect.new()
	_whole.name = "WholePhoto"
	_whole.texture = load(IMAGES + "item_photo.png")
	_whole.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_whole.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_whole.set_anchors_preset(Control.PRESET_FULL_RECT)
	table.add_child(_whole)

	_hint = Label.new()
	_hint.name = "PuzzleHint"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color("ffd76a"))
	content.add_child(_hint)

	var close := Button.new()
	close.name = "ClosePuzzle"
	close.text = "Close"
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(queue_free)
	content.add_child(close)


func _frame_style(picked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = HIGHLIGHT if picked else Color(0, 0, 0, 0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

