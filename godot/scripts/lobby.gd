# The lobby (spec 03, tidied up in 03c): create a room or join one.
# Spec 15: the host can resume a saved game; a new game over a save asks first.
# All network work happens in network.gd; this script only shows it.
# main.gd hands in its network (net); started alone, the lobby makes its own.
extends Control

const NetworkScript = preload("res://scripts/net/network.gd")

var net: Node = null

var _create_button: Button
var _address_field: LineEdit
var _join_button: Button
var _status_label: Label
var _room_code_label: Label
var _players_label: Label
var _start_button: Button
var _resume_button: Button
var _confirm_box: Control  # "Start a new game? The saved game will be lost."


func _ready() -> void:
	if net == null:
		net = NetworkScript.new()
		net.name = "Network"
		add_child(net)
	net.changed.connect(_refresh)
	_build_ui()
	_refresh()


func _on_create_pressed() -> void:
	net.host_room()


func _on_join_pressed() -> void:
	net.join(_address_field.text)


func _on_start_pressed() -> void:
	if net.has_saved_game():
		_confirm_box.visible = true  # ask first: the save would be lost
	else:
		net.start_game()


func _on_yes_new_game_pressed() -> void:
	_confirm_box.visible = false
	net.start_game()


func _on_cancel_new_game_pressed() -> void:
	_confirm_box.visible = false


func _on_resume_pressed() -> void:
	net.resume_game()


func _refresh() -> void:
	_status_label.text = net.status
	_status_label.visible = net.room_code == ""  # an open room: the big code says it all (03c)
	_room_code_label.text = ("Room code: " + net.room_code) if net.room_code != "" else ""
	_room_code_label.visible = net.room_code != ""  # no empty gap before a room exists
	var names := []
	for index in net.players:
		names.append("Player %d%s" % [index + 1, " (you)" if index == net.my_index else ""])
	_players_label.text = "Players: " + (", ".join(names) if not names.is_empty() else "nobody yet")
	_players_label.visible = not names.is_empty()
	var busy: bool = net.is_active()
	_create_button.disabled = busy
	_join_button.disabled = busy
	_address_field.editable = not busy
	_start_button.visible = net.connected and net.my_index == 0
	_start_button.disabled = not net.can_start()
	_start_button.text = "Start game" if net.can_start() else "Start game (needs %d players)" % 3
	var host_with_save: bool = net.connected and net.my_index == 0 and net.game.is_empty() and net.has_saved_game()
	_resume_button.visible = host_with_save
	_resume_button.disabled = not net.can_resume()
	_resume_button.text = "Resume saved game" if net.can_resume() else "Resume saved game (needs %d players)" % 3
	if not host_with_save:
		_confirm_box.visible = false


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
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)

	var title := Label.new()
	title.text = "Merry Scary Christmas: Lobby"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	page.add_child(title)

	_create_button = Button.new()
	_create_button.name = "CreateButton"
	_create_button.text = "Create room"
	_create_button.custom_minimum_size = Vector2(532, 52)  # as wide as the code field + Join (03c)
	_create_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_create_button.pressed.connect(_on_create_pressed)
	page.add_child(_create_button)

	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 12)
	page.add_child(join_row)
	_address_field = LineEdit.new()
	_address_field.name = "AddressField"
	_address_field.placeholder_text = "Room code, e.g. KRTW"
	_address_field.custom_minimum_size = Vector2(380, 56)  # big, but not the whole width (03c)
	_address_field.add_theme_font_size_override("font_size", 28)
	join_row.add_child(_address_field)
	_join_button = Button.new()
	_join_button.name = "JoinButton"
	_join_button.text = "Join"
	_join_button.custom_minimum_size = Vector2(140, 56)
	_join_button.pressed.connect(_on_join_pressed)
	_paint_button(_join_button, Color("2f7d3a"))  # green: its own colour (03c)
	join_row.add_child(_join_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # full width: wrapping is safe here
	_status_label.add_theme_color_override("font_color", Color("ffd76a"))
	page.add_child(_status_label)

	_room_code_label = Label.new()
	_room_code_label.name = "RoomCodeLabel"
	_room_code_label.add_theme_font_size_override("font_size", 40)
	_room_code_label.add_theme_color_override("font_color", Color("d4af37"))
	page.add_child(_room_code_label)

	_players_label = Label.new()
	_players_label.name = "PlayersLabel"
	page.add_child(_players_label)

	# Start and Resume side by side, so the question below still fits on the screen.
	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 12)
	page.add_child(start_row)
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.custom_minimum_size = Vector2(0, 56)
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button.pressed.connect(_on_start_pressed)
	start_row.add_child(_start_button)

	_resume_button = Button.new()
	_resume_button.name = "ResumeButton"
	_resume_button.custom_minimum_size = Vector2(0, 56)
	_resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resume_button.pressed.connect(_on_resume_pressed)
	start_row.add_child(_resume_button)

	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "ConfirmNewGame"
	_confirm_box.visible = false
	page.add_child(_confirm_box)
	var question := Label.new()
	question.name = "ConfirmNewGameLabel"
	question.text = "Start a new game? The saved game will be lost."
	question.add_theme_color_override("font_color", Color("ffd76a"))
	_confirm_box.add_child(question)
	var answers := HBoxContainer.new()
	answers.add_theme_constant_override("separation", 12)
	_confirm_box.add_child(answers)
	var yes := Button.new()
	yes.name = "YesNewGameButton"
	yes.text = "Yes, new game"
	yes.pressed.connect(_on_yes_new_game_pressed)
	answers.add_child(yes)
	var cancel := Button.new()
	cancel.name = "CancelNewGameButton"
	cancel.text = "Cancel"
	cancel.pressed.connect(_on_cancel_new_game_pressed)
	answers.add_child(cancel)


# A button in its own colour: lighter on hover, darker when pressed, faded when disabled.
func _paint_button(button: Button, colour: Color) -> void:
	var looks := {"normal": colour, "hover": colour.lightened(0.15), "pressed": colour.darkened(0.2),
		"disabled": Color(colour, 0.35), "focus": colour.lightened(0.15)}
	for state in looks:
		var box := StyleBoxFlat.new()
		box.bg_color = looks[state]
		box.set_corner_radius_all(6)
		box.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)

