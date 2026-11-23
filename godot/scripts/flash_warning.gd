# The flashing warning (spec 34): before the story on each device. Says that the game has
# flickering lights, offers "Reduce flashing", and sends `accepted` on Continue (or Enter/Space).
extends Control

signal accepted

const ButtonStyle = preload("res://scripts/button_style.gd")
const Comfort = preload("res://scripts/comfort.gd")
const CREAM := Color("e8d9c0")
const GOLD := Color("ffd76a")

var net: Node = null  # main.gd hands this in like for every screen; not needed here
var _switch: Button
var _done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color("0b0809")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -330
	box.offset_right = 330
	box.offset_top = -170
	box.offset_bottom = 170
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	add_child(box)
	var heading := Label.new()
	heading.name = "WarningHeading"
	heading.text = "Before you play"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", GOLD)
	box.add_child(heading)
	var text := Label.new()
	text.name = "WarningText"
	text.text = "This game contains flickering lights that may affect people with photosensitive epilepsy.\nYou can switch the flickering off here, or later on the pause screen."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(660, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	text.add_theme_color_override("font_color", CREAM)
	box.add_child(text)
	_switch = Button.new()
	_switch.name = "ReduceFlashingSwitch"
	_switch.custom_minimum_size = Vector2(300, 48)
	_switch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_switch.add_theme_font_size_override("font_size", 20)
	ButtonStyle.make_clickable(_switch)
	_switch.focus_mode = Control.FOCUS_NONE  # Enter/Space mean Continue
	_switch.pressed.connect(func() -> void:
		Comfort.reduce_flashing = not Comfort.reduce_flashing
		_switch.text = Comfort.switch_text())
	_switch.text = Comfort.switch_text()
	box.add_child(_switch)
	var go_on := Button.new()
	go_on.name = "WarningContinue"
	go_on.text = "Continue"
	go_on.custom_minimum_size = Vector2(240, 56)
	go_on.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_on.add_theme_font_size_override("font_size", 26)
	go_on.focus_mode = Control.FOCUS_NONE
	go_on.pressed.connect(_continue)
	box.add_child(go_on)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_continue()


func _continue() -> void:
	if _done:
		return
	_done = true
	accepted.emit()
