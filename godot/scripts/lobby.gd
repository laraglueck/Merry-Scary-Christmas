# The lobby (spec 03): create a room or join one, then share a counter.
# All network work happens in network.gd; this script only shows it.
extends Control

const NetworkScript = preload("res://scripts/net/network.gd")

var net: Node

var _create_button: Button
var _address_field: LineEdit
var _join_button: Button
var _status_label: Label
var _players_label: Label
var _counter_label: Label
var _add_button: Button


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	net.changed.connect(_refresh)
	_build_ui()
	_refresh()


func _on_create_pressed() -> void:
	net.host_room()


func _on_join_pressed() -> void:
	net.join_room(_address_field.text)


func _on_add_pressed() -> void:
	net.add_one()


func _refresh() -> void:
	_status_label.text = net.status
	var names := []
	for index in net.players:
		names.append("Player %d%s" % [index + 1, " (you)" if index == net.my_index else ""])
	_players_label.text = "Players: " + (", ".join(names) if not names.is_empty() else "nobody yet")
	_counter_label.text = "Counter: %d" % net.counter
	var busy: bool = net.is_active()
	_create_button.disabled = busy
	_join_button.disabled = busy
	_address_field.editable = not busy
	_add_button.disabled = not net.connected


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
	_create_button.custom_minimum_size = Vector2(0, 52)
	_create_button.pressed.connect(_on_create_pressed)
	page.add_child(_create_button)

	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 12)
	page.add_child(join_row)
	_address_field = LineEdit.new()
	_address_field.name = "AddressField"
	_address_field.placeholder_text = "Host address, e.g. 192.168.1.42 (same computer: 127.0.0.1)"
	_address_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(_address_field)
	_join_button = Button.new()
	_join_button.name = "JoinButton"
	_join_button.text = "Join"
	_join_button.custom_minimum_size = Vector2(120, 0)
	_join_button.pressed.connect(_on_join_pressed)
	join_row.add_child(_join_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # full width: wrapping is safe here
	_status_label.add_theme_color_override("font_color", Color("ffd76a"))
	page.add_child(_status_label)

	_players_label = Label.new()
	_players_label.name = "PlayersLabel"
	page.add_child(_players_label)

	var counter_row := HBoxContainer.new()
	counter_row.add_theme_constant_override("separation", 16)
	page.add_child(counter_row)
	_counter_label = Label.new()
	_counter_label.name = "CounterLabel"
	_counter_label.add_theme_font_size_override("font_size", 28)
	counter_row.add_child(_counter_label)
	_add_button = Button.new()
	_add_button.name = "AddButton"
	_add_button.text = "+1"
	_add_button.custom_minimum_size = Vector2(90, 48)
	_add_button.pressed.connect(_on_add_pressed)
	counter_row.add_child(_add_button)
