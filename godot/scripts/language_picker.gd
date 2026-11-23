# The language picker (spec 34): "English · Deutsch · Português", top right on the title.
# The chosen one is gold; a click switches every screen at once and is remembered (lang.gd).
# Only for this device: every player can play in their own language.
extends HBoxContainer

signal language_changed(code: String)

const Lang = preload("res://scripts/lang.gd")
const ButtonStyle = preload("res://scripts/button_style.gd")

var _buttons := {}  # code -> its button


func _ready() -> void:
	name = "LanguagePicker"
	add_theme_constant_override("separation", 6)
	for language in Lang.LANGUAGES:
		var button := Button.new()
		button.name = "Language_" + language["code"]
		button.text = language["name"]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # a language's own name
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 36)
		button.add_theme_font_size_override("font_size", 15)
		ButtonStyle.make_clickable(button)
		button.pressed.connect(choose.bind(language["code"]))
		add_child(button)
		_buttons[language["code"]] = button
	_show_choice()


# Also when the language was changed somewhere else.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _buttons.is_empty():
		_show_choice()


func choose(code: String) -> void:
	if code == Lang.current():
		return
	Lang.set_language(code)
	_show_choice()
	language_changed.emit(code)


func _show_choice() -> void:
	for code in _buttons:
		var chosen: bool = code == Lang.current()
		_buttons[code].modulate = Color.WHITE if chosen else Color(0.7, 0.7, 0.7, 0.8)
		_buttons[code].add_theme_color_override("font_color", ButtonStyle.GOLD if chosen else ButtonStyle.CREAM)
