# The title screen (spec 11): picture, game name, music, spoken intro and "Start".
# Shown on every device on its own before the lobby; nothing here goes over the network.
# main.gd listens to start_pressed and then shows the lobby. Started alone (⌘ R),
# "Start" does nothing.
extends Control

signal start_pressed

const IMAGES := "res://assets/images/"
const SOUNDS := "res://assets/sounds/"

var net: Node = null  # main.gd hands this in like for every screen; the title doesn't need it


func _ready() -> void:
	_build_ui()
	_add_sound("Music", "music_lobby.mp3", true)
	_add_sound("Voice", "voice_title.mp3", false)


func _on_start_pressed() -> void:
	start_pressed.emit()


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var dark := ColorRect.new()  # shows while the picture loads, and around it
	dark.color = Color("1b1012")
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dark)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(IMAGES + "ui_title.webp")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.alignment = BoxContainer.ALIGNMENT_END
	page.add_theme_constant_override("separation", 24)
	add_child(page)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Merry Scary Christmas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	title.add_theme_color_override("font_outline_color", Color("1b1012"))
	title.add_theme_constant_override("outline_size", 12)
	page.add_child(title)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.custom_minimum_size = Vector2(260, 64)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 28)
	start.pressed.connect(_on_start_pressed)
	page.add_child(start)

	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 80)
	page.add_child(bottom_space)


func _add_sound(node_name: String, file_name: String, looping: bool) -> void:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	var stream: AudioStreamMP3 = load(SOUNDS + file_name)
	stream.loop = looping
	player.stream = stream
	# Plays by itself in the real game. Not in the headless test run: there is no sound
	# card there, and a sound still playing at the end shows up as a leak warning.
	player.autoplay = DisplayServer.get_name() != "headless"
	add_child(player)
