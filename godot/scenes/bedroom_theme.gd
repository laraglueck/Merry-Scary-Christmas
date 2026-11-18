
extends RefCounted

# Merry Scary Christmas - Bedroom visual theme

const BACKGROUND = Color("#151b20")
const PANEL = Color("#30272a")
const BUTTON = Color("#79483f")
const BUTTON_HOVER = Color("#995b4e")
const BUTTON_PRESSED = Color("#58352f")
const TEXT = Color("#f4e7d1")
const GOLD = Color("#d4a35b")
const BORDER = Color("#796044")


static func apply_theme(root: Control) -> void:
	# Dark background
	var background := ColorRect.new()
	background.name = "HorrorBackground"
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	root.add_child(background)
	root.move_child(background, 0)

	# Main layout
	var container := root.get_node_or_null(
		"VBoxContainer"
	) as VBoxContainer

	if container == null:
		return

	container.add_theme_constant_override(
		"separation", 12
	)

	# Style all buttons and symbol wheels.
	for child in container.get_children():
		if child is Button:
			_style_button(child)

		if child is OptionButton:
			_style_button(child)

		if child is Label:
			_style_label(child)


static func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_make_style(BUTTON)
	)

	button.add_theme_stylebox_override(
		"hover",
		_make_style(BUTTON_HOVER)
	)

	button.add_theme_stylebox_override(
		"pressed",
		_make_style(BUTTON_PRESSED)
	)

	button.add_theme_stylebox_override(
		"disabled",
		_make_style(PANEL)
	)

	button.add_theme_color_override(
		"font_color", TEXT
	)

	button.add_theme_color_override(
		"font_hover_color", TEXT
	)

	button.add_theme_color_override(
		"font_pressed_color", TEXT
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color("#8c8179")
	)

	button.add_theme_font_size_override(
		"font_size", 18
	)

	button.custom_minimum_size.y = 45


static func _style_label(label: Label) -> void:
	label.add_theme_color_override(
		"font_color", TEXT
	)

	label.add_theme_font_size_override(
		"font_size", 17
	)


static func _make_style(
	bg_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = bg_color
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)

	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	return style
