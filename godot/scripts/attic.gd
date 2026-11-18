# The attic (spec 16): the code lock with three dials, then the final choice
# beside the sleeping Scary Jingles.
# Offline (no net): one screen with its own game, already in the attic, for
# trying it out with Cmd R. Online (main.gd hands in a net with a game): actions
# go to the host, and the shared game comes back. The rules live in
# attic_rules.gd and game_rules.gd; this script only shows the state and reacts
# to keys and clicks.
extends Control

const GameRules = preload("res://scripts/rules/game_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")

const IMAGES := "res://assets/images/"
const HIGHLIGHT := Color("ffd76a")
# The three dials, in the order of the rooms' fuses (see the house plan).
const DIAL_COLOURS := [Color("b03a3a"), Color("3f8a4f"), Color("c9a227")]
# Scary Jingles in his armchair, on the left of the floor, facing into the room.
# Rect2(x, y, width, height) on the 1152 x 648 screen, measured on room_attic.webp.
const JINGLES_RECT := Rect2(560, 200, 240, 292)
const KEY_RECT := Rect2(812, 440, 72, 66)  # the key on the floor beside his armchair
const CHOICES := [
	{"node": "ChoiceLockIn", "choice": "lock_in", "label": "Lock him in"},
	{"node": "ChoiceReconcile", "choice": "reconcile", "label": "Leave the photo and cookies"},
]
const GREYED_OUT := 0.5  # the photo choice without the photo
# Effects (spec 19)
const SOUNDS := "res://assets/sounds/"
const STIR_SECONDS := 1.0          # how long he is awake after a wrong code
const SNORE_LOCKED_DB := -18.0     # heard through the locked door
const SNORE_OPEN_DB := -8.0
const DIMMED := Color(0.45, 0.45, 0.5)

# -1 means: a new random game at every start. Tests set a fixed seed.
@export var seed_value := -1
# Offline only: does the team already have the photo from the bedroom?
@export var has_photo := false
var net: Node = null  # set by main.gd for online play

var game: Dictionary       # offline: our own game; online: the shared game
var _dials := [1, 1, 1]    # what this player has set on the dials (red, green, gold)
var _dial_index := 0       # the highlighted dial (keys)
var _choice_index := 0     # the highlighted choice (keys)

# Nodes we change later (built in _build_ui)
var _background: TextureRect
var _lock_panel: PanelContainer
var _dial_buttons: Array[Button] = []
var _jingles: TextureRect
var _key: TextureRect
var _choice_buttons: Array[Button] = []
var _message: Label
var _snore: AudioStreamPlayer
var _lock_sound: AudioStreamPlayer
var _stirring := false

# Sounds this screen played (or would have played in the headless test run).
var sounds_played: Array[String] = []
var _seen := {}  # what the shared game showed last time: unlocked, penalty


func _ready() -> void:
	if _online():
		game = net.game
		net.game_changed.connect(_on_game_changed)
	else:
		game = _offline_game()
	_build_ui()
	_message.text = game.get("last_event", "")
	_seen = _what_happened_so_far()
	_refresh()
	if DisplayServer.get_name() != "headless":
		_snore.play()  # not in the test run: no sound card


func _online() -> bool:
	return net != null and not net.game.is_empty()


# Offline: a real game from the rules, with the team already upstairs.
func _offline_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var new_game := GameRules.new_game(rng)
	new_game["location"] = "attic"
	if has_photo:
		InventoryRules.add(new_game, "photo")
	new_game["last_event"] = ""
	return new_game


func _on_game_changed() -> void:
	if not _online():
		return  # game is over (host left); main.gd switches the screen
	game = net.game
	_message.text = game["last_event"]
	_react()
	_refresh()


# Online: the host decides. Offline: the same rules, right here.
func _send(action: String, data: Dictionary) -> void:
	if _online():
		net.send_action(action, data)
	else:
		GameRules.apply(game, 0, action, data)
		_message.text = game["last_event"]
		_react()
		_refresh()


func _attic() -> Dictionary:
	return game.get("attic", AtticRules.create())  # a game saved before spec 16 has none yet


func _is_locked() -> bool:
	return not _attic()["unlocked"]


# What this player has set on the three dials (for tests too).
func dial_values() -> Array:
	return _dials.duplicate()


# ---------- keys ----------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_hall()
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif _is_locked() and event.is_action_pressed("ui_up"):
		_turn_dial(_dial_index, 1)
	elif _is_locked() and event.is_action_pressed("ui_down"):
		_turn_dial(_dial_index, -1)
	elif event.is_action_pressed("ui_accept"):
		if _is_locked():
			_try_code()
		else:
			_choose(_choice_index)
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


# Left and right move between the dials, or between the two choices.
func _move(step: int) -> void:
	if _is_locked():
		_dial_index = clampi(_dial_index + step, 0, 2)
	else:
		_choice_index = clampi(_choice_index + step, 0, CHOICES.size() - 1)
	_refresh()


# ---------- actions (key or click) ----------

# A dial turns through 1 to 9 and starts again: 9 + 1 = 1, 1 - 1 = 9.
func _turn_dial(index: int, step: int) -> void:
	_dial_index = index
	_dials[index] = posmod(_dials[index] - 1 + step, 9) + 1
	_refresh()


func _try_code() -> void:
	_send("try_attic_code", {"dials": _dials.duplicate()})


func _choose(index: int) -> void:
	_choice_index = index
	_send("choose_ending", {"choice": CHOICES[index]["choice"]})


func _go_to_hall() -> void:
	_send("go_to", {"place": "hall"})  # the whole team walks back down (spec 07)


# ---------- effects (spec 19): sounds, and he stirs ----------

# The picture Jingles shows right now (for tests too).
func jingles_picture() -> String:
	return _jingles.texture.resource_path.get_file()


func _what_happened_so_far() -> Dictionary:
	return {"unlocked": _attic()["unlocked"], "penalty": game.get("penalty_seconds", 0)}


# Something changed in the shared game (here or on a teammate's device): react to it.
func _react() -> void:
	var now := _what_happened_so_far()
	if now["unlocked"] and not _seen["unlocked"]:
		_play(_lock_sound, "sfx_key_lock.mp3")
	elif not now["unlocked"] and now["penalty"] > _seen["penalty"]:
		_stir()  # the lock rattled: a wrong code
	_seen = now


# A wrong code: he wakes for a moment, the snoring stops, then he sleeps on.
func _stir() -> void:
	_stirring = true
	_snore.stream_paused = true
	get_tree().create_timer(STIR_SECONDS).timeout.connect(_fall_asleep)


func _fall_asleep() -> void:
	_stirring = false
	_snore.stream_paused = false
	_refresh()


func _play(player: AudioStreamPlayer, file_name: String) -> void:
	sounds_played.append(file_name)
	if DisplayServer.get_name() != "headless":
		player.play()


# ---------- showing the current state ----------

func _refresh() -> void:
	var locked := _is_locked()
	_lock_panel.visible = locked
	_background.modulate = DIMMED if locked else Color.WHITE

	for i in 3:
		var button := _dial_buttons[i]
		button.text = str(_dials[i])
		var border: Color = HIGHLIGHT if i == _dial_index else DIAL_COLOURS[i]
		button.add_theme_stylebox_override("normal", _dial_style(DIAL_COLOURS[i], border))

	# Seen asleep through the door while locked (dimmed like the room), awake for a moment
	# when he stirs.
	_jingles.visible = true
	_jingles.texture = load(IMAGES + ("char_jingles_awake.png" if _stirring else "char_jingles_asleep.png"))
	_jingles.modulate = DIMMED if locked and not _stirring else Color.WHITE
	_snore.volume_db = SNORE_LOCKED_DB if locked else SNORE_OPEN_DB
	_key.visible = not locked and not InventoryRules.has(game, "key")
	var photo := InventoryRules.has(game, "photo")
	for i in _choice_buttons.size():
		var button := _choice_buttons[i]
		button.visible = not locked
		var border := HIGHLIGHT if i == _choice_index else Color("5c4a3a")
		button.add_theme_stylebox_override("normal", _box(Color(0.1, 0.07, 0.07, 0.85), border, 3))
	# Without the photo the second choice stays clickable, so the reason can be shown.
	_choice_buttons[1].modulate.a = 1.0 if photo else GREYED_OUT


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var backdrop := ColorRect.new()
	backdrop.color = Color("1b1012")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_background = TextureRect.new()
	_background.name = "Background"
	_background.texture = load(IMAGES + "room_attic.webp")
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_background)

	# Scary Jingles, asleep in his armchair (seen once the lock is open).
	_jingles = TextureRect.new()
	_jingles.name = "Jingles"
	_jingles.texture = load(IMAGES + "char_jingles_asleep.png")
	_jingles.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_jingles.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_jingles.position = JINGLES_RECT.position
	_jingles.size = JINGLES_RECT.size
	_jingles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_jingles)

	# The key to the attic door, on the floor beside him.
	_key = TextureRect.new()
	_key.name = "Key"
	_key.texture = load(IMAGES + "item_key.png")
	_key.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_key.position = KEY_RECT.position
	_key.size = KEY_RECT.size
	_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_key)

	# The two choices, bottom right.
	var choices := HBoxContainer.new()
	choices.name = "Choices"
	choices.position = Vector2(470, 530)
	choices.add_theme_constant_override("separation", 16)
	add_child(choices)
	for i in CHOICES.size():
		var button := _button(choices, CHOICES[i]["node"], CHOICES[i]["label"])
		button.pressed.connect(_choose.bind(i))
		_choice_buttons.append(button)

	# Title, way back, and message line.
	var title := _label(self, "The Attic", 34)
	title.position = Vector2(24, 12)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	var back := _button(self, "BackButton", "Back to the hall")
	back.position = Vector2(940, 16)
	back.pressed.connect(_go_to_hall)
	_message = _label(self, "", 22)
	_message.name = "Message"
	_message.position = Vector2(24, 596)
	_message.size = Vector2(1100, 40)
	_message.add_theme_color_override("font_color", Color("ffd76a"))
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 6)

	_build_lock()

	# Snoring that goes on and on, and the lock opening.
	_snore = AudioStreamPlayer.new()
	_snore.name = "Snore"
	var snore_stream: AudioStreamMP3 = load(SOUNDS + "sfx_snore.mp3").duplicate()
	snore_stream.loop = true
	_snore.stream = snore_stream
	_snore.volume_db = SNORE_LOCKED_DB
	add_child(_snore)
	_lock_sound = AudioStreamPlayer.new()
	_lock_sound.name = "LockSound"
	_lock_sound.stream = load(SOUNDS + "sfx_key_lock.mp3")
	add_child(_lock_sound)


# The locked attic door: three dials and a Try button.
func _build_lock() -> void:
	_lock_panel = PanelContainer.new()
	_lock_panel.name = "LockPanel"
	_lock_panel.position = Vector2(40, 110)  # on the left, so Jingles can be seen on the right
	_lock_panel.size = Vector2(520, 380)
	_lock_panel.add_theme_stylebox_override("panel", _box(Color("2a1d17"), Color("5c4a3a"), 6))
	add_child(_lock_panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	_lock_panel.add_child(content)

	var heading := _label(content, "The attic door is locked.", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("e8d9c0"))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	for i in 3:
		var dial := Button.new()
		dial.name = "Dial%d" % i
		dial.custom_minimum_size = Vector2(100, 120)
		dial.add_theme_font_size_override("font_size", 56)
		dial.add_theme_stylebox_override("hover", _dial_style(DIAL_COLOURS[i], HIGHLIGHT))
		dial.add_theme_stylebox_override("pressed", _dial_style(DIAL_COLOURS[i], HIGHLIGHT))
		dial.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		dial.pressed.connect(_turn_dial.bind(i, 1))
		row.add_child(dial)
		_dial_buttons.append(dial)

	var try_button := _button(content, "TryButton", "Try the code")
	try_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	try_button.pressed.connect(_try_code)

	var hint := _label(content, "Click a dial to turn it. Keys: left/right choose, up/down turn, Enter tries.", 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_color_override("font_color", Color("b8a88e"))


func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Node, node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_stylebox_override("normal", _box(Color(0.1, 0.07, 0.07, 0.85), Color("5c4a3a"), 3))
	button.add_theme_stylebox_override("hover", _box(Color(0.2, 0.14, 0.1, 0.95), HIGHLIGHT, 3))
	button.add_theme_stylebox_override("pressed", _box(Color(0.2, 0.14, 0.1, 0.95), HIGHLIGHT, 3))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(button)
	return button


func _dial_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill.darkened(0.55)
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(50)
	return style


func _box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	return style
