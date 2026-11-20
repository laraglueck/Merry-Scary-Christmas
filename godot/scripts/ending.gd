# The end screen (spec 16): one screen for the three ways a game ends.
# main.gd shows it when the phase is "merry", "scary" or "midnight" and hands in
# that phase as `place`. Offline (Cmd R) it shows `place` with an empty game.
extends Control

const ClockRules = preload("res://scripts/rules/clock_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const Title = preload("res://scripts/title.gd")

const IMAGES := "res://assets/images/"
const GIFTS := ["gift_1", "gift_2", "gift_3"]
const ENDINGS := {
	"merry": {"picture": "ui_win_merry.webp", "title": "Merry Christmas!", "colour": Color("ffd76a"),
			"line": "Scary Jingles remembered who he was.", "sounds": ["music_merry.mp3"]},
	"scary": {"picture": "ui_win_scary.webp", "title": "Scary Christmas!", "colour": Color("e05a4a"),
			"line": "Scary Jingles is locked in. The presents are safe.", "sounds": ["music_scary.mp3"]},
	"midnight": {"picture": "ui_lose.webp", "title": "Midnight", "colour": Color("a9c4e8"),
			"line": "The clock struck twelve. Scary Jingles has won.", "sounds": ["sfx_lose.mp3"]},
}

@export var place := "merry"  # set by main.gd: the phase that ended the game
var net: Node = null          # set by main.gd
const SOUNDS := "res://assets/sounds/"

# Sounds this screen played (or would have played in the headless test run), spec 20.
var sounds_played: Array[String] = []
const WAKE_SECONDS := 5.0    # midnight: how long the wake-up shows before the end screen
const WAKE_FADE_IN := 2.0     # how slowly his face comes out of the dark


func _ready() -> void:
	var game: Dictionary = net.game if net != null and not net.game.is_empty() else {"phase": place}
	var ending: Dictionary = ENDINGS.get(place, ENDINGS["midnight"])
	_build_ui(ending, _result_text(game), str(game.get("last_event", "")))
	if place == "midnight":
		_wake_up()  # spec 21: the clock strikes and he wakes, then the end screen
	else:
		for file_name in ending["sounds"]:
			_play(file_name)


# Midnight (spec 21): a dark screen, the clock strikes, and Scary Jingles is wide awake.
# After a few seconds the end screen fades in with the lose music.
func _wake_up() -> void:
	var wake := ColorRect.new()
	wake.name = "WakeUp"
	wake.color = Color("050304")
	wake.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wake)
	var jingles := TextureRect.new()
	jingles.name = "WakeUpJingles"
	jingles.texture = load(IMAGES + "char_jingles_awake.png")
	jingles.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jingles.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jingles.set_anchors_preset(Control.PRESET_FULL_RECT)
	jingles.offset_top = 40
	jingles.offset_bottom = -40
	jingles.modulate.a = 0.0
	wake.add_child(jingles)
	create_tween().tween_property(jingles, "modulate:a", 1.0, WAKE_FADE_IN)
	_play("sfx_clock_chime.mp3")
	get_tree().create_timer(WAKE_SECONDS).timeout.connect(show_ending)


# After the wake-up: the end screen with its picture and the lose music (tests call it too).
func show_ending() -> void:
	var wake := get_node_or_null("WakeUp")
	if wake == null or not wake.visible:
		return
	wake.visible = false
	for file_name in ENDINGS["midnight"]["sounds"]:
		_play(file_name)


# Each ending's sounds (Merry and Scary: only their music box, no drum fanfare since spec 29).
func _play(file_name: String) -> void:
	sounds_played.append(file_name)
	if DisplayServer.get_name() == "headless":
		return  # no sound card in the test run
	var player := AudioStreamPlayer.new()
	player.name = "Sound_" + file_name.get_basename()
	player.stream = load(SOUNDS + file_name)
	add_child(player)
	player.play()


# "Presents found: 2 of 3", and for a win the time that was left.
func _result_text(game: Dictionary) -> String:
	var found := 0
	for gift in GIFTS:
		if InventoryRules.has(game, gift):
			found += 1
	var text := "Presents found: %d of %d" % [found, GIFTS.size()]
	if place != "midnight" and game.has("seconds_played"):
		text += "   ·   %s before midnight" % ClockRules.as_text(ClockRules.time_left(game))
	return text


func _build_ui(ending: Dictionary, result: String, last_event: String) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("120b0c")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(IMAGES + ending["picture"])
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	if place == "merry":
		# Spec 29: gentle snow over the Christmas Eve picture, behind the words.
		var snow := Title.make_snow(1152)
		snow.name = "MerrySnow"
		snow.amount = 90
		snow.speed_scale = 0.7
		add_child(snow)

	# A dark band at the bottom, so the words stay readable on any picture.
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.6)
	band.position = Vector2(0, 470)
	band.size = Vector2(1152, 178)
	add_child(band)

	var words := VBoxContainer.new()
	words.position = Vector2(0, 482)
	words.size = Vector2(1152, 160)
	words.add_theme_constant_override("separation", 6)
	add_child(words)
	var title := _label(words, "PlaceTitle", ending["title"], 56)
	title.add_theme_color_override("font_color", ending["colour"])
	_label(words, "Line", ending["line"], 24)
	var result_label := _label(words, "Result", result, 20)
	result_label.add_theme_color_override("font_color", Color("d8c8ae"))

	# What happened last, e.g. "Player 2 took the key and locked Scary Jingles in."
	var message := _label(self, "Message", last_event, 18)
	message.position = Vector2(0, 16)
	message.size = Vector2(1152, 30)
	message.add_theme_color_override("font_color", Color("ffd76a"))

	# Spec 17: the host takes everyone back to the lobby (network.end_game);
	# Players 2 and 3 wait for the host. Started on its own (no network): neither.
	var online: bool = net != null and net.get("connected") == true  # get(): a test's stand-in net may not have it
	var index: int = net.get("my_index") if online else -1
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back to the lobby"
	back.visible = online and index == 0
	back.position = Vector2(916, 584)
	back.custom_minimum_size = Vector2(216, 48)
	back.add_theme_font_size_override("font_size", 20)
	_paint_red(back)  # red, so it is clear you can click it (manual test, spec 17)
	back.pressed.connect(_on_back_pressed)
	add_child(back)
	var wait := _label(self, "WaitLabel", "Waiting for Player 1...", 18)
	wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wait.position = Vector2(760, 596)
	wait.size = Vector2(372, 30)
	wait.visible = online and index > 0


# Red: lighter on hover, darker when pressed.
func _paint_red(button: Button) -> void:
	var red := Color("c0392b")
	var looks := {"normal": red, "hover": red.lightened(0.15), "pressed": red.darkened(0.2), "focus": red.lightened(0.15)}
	for state in looks:
		var box := StyleBoxFlat.new()
		box.bg_color = looks[state]
		box.set_corner_radius_all(6)
		box.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _on_back_pressed() -> void:
	if net != null:
		net.end_game()


func _label(parent: Node, node_name: String, text: String, size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
