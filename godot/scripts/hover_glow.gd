# Spec 34: everything you can click in a room glows softly while the mouse is over it.
# One look for the hall and every room: a thin gold edge, a faint gold fill and a soft
# gold halo. Nothing glows without the mouse, so finding things stays part of the game.
extends RefCounted

const GOLD := Color("ffd76a")
const LIGHT_UP := 1.35  # a thing to pick up gets this much brighter on hover


# The glow itself (also used by the tests).
static func glow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GOLD, 0.06)
	style.border_color = GOLD  # the gold edge of spec 24, now with a glow
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(GOLD, 0.45)
	style.shadow_size = 16
	return style


# A click area over the picture (door, window, clock, ...): invisible, glowing on hover.
static func spot(button: Button) -> void:
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var glow := glow_style()
	for state in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, glow)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# A thing to pick up (present, photo piece, cookies, key, note): on hover it lights up and a
# soft halo shows behind it; afterwards it looks as before (a dimmed thing stays dimmed).
static func item(button: TextureButton) -> void:
	var halo := Panel.new()
	halo.name = "HoverGlow"
	halo.show_behind_parent = true
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := glow_style()
	style.border_color = Color(GOLD, 0.0)  # only the halo, no edge round the picture
	style.set_corner_radius_all(40)
	halo.add_theme_stylebox_override("panel", style)
	halo.visible = false
	button.add_child(halo)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func() -> void:
		if not button.has_meta("hover_glow_base"):
			button.set_meta("hover_glow_base", button.modulate)
		var base: Color = button.get_meta("hover_glow_base")
		button.modulate = Color(base.r * LIGHT_UP, base.g * LIGHT_UP, base.b * LIGHT_UP, base.a)
		halo.visible = true)
	button.mouse_exited.connect(func() -> void:
		if button.has_meta("hover_glow_base"):
			button.modulate = button.get_meta("hover_glow_base")
			button.remove_meta("hover_glow_base")
		halo.visible = false)
