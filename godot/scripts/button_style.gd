# One look for the small buttons on top of the game (spec 29): "?" and "Pause".
# Dark with a gold frame, lighter on hover, the hand cursor: you see at once you can click them.
extends RefCounted

const GOLD := Color("ffd76a")
const CREAM := Color("e8d9c0")


static func make_clickable(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(Color(0.08, 0.05, 0.04, 0.85)))
	button.add_theme_stylebox_override("hover", _box(Color(0.32, 0.22, 0.10, 0.95)))
	button.add_theme_stylebox_override("pressed", _box(Color(0.45, 0.32, 0.12, 1.0)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func _box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(6)
	return box
