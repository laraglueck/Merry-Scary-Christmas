# The bathroom (spec 10): the room behind the green fuse, with the tap lock.
# Offline (no net): one screen with its own game, for trying it out with Cmd R.
# Online (main.gd hands in a net with a game): actions go to the host, and the
# shared game comes back. The rules live in bathroom_rules.gd and game_rules.gd;
# this script only shows the state and reacts to keys and clicks.
extends Control

const HoverGlow = preload("res://scripts/hover_glow.gd")  # spec 34

const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")
const BathroomRules = preload("res://scripts/rules/bathroom_rules.gd")
const InventoryRules = preload("res://scripts/rules/inventory_rules.gd")
const RoomStage = preload("res://scripts/room_stage.gd")
const Settings = preload("res://scripts/settings.gd")

const IMAGES := "res://assets/images/"
const GREEN_FUSE := 1  # the green fuse lights the bathroom
# Until the bedroom exists, the mirror shows these example chest symbols.
const EXAMPLE_WHEELS := ["bell", "star", "tree"]

# The clickable spots, left to right (the arrow keys follow this order).
# Rect2(x, y, width, height) on the 1152 x 648 screen, measured on room_bathroom_lit.webp.
# The door is on the right, as in the house plan. If a new picture moves things, change these numbers.
const SPOTS := [
	{"name": "bathtub", "label": "Bathtub", "rect": Rect2(112, 378, 420, 175)},
	{"name": "cold_tap", "label": "Cold", "rect": Rect2(678, 300, 52, 52)},
	{"name": "hot_tap", "label": "Warm", "rect": Rect2(734, 300, 52, 52)},
	{"name": "mirror", "label": "Mirror", "rect": Rect2(616, 128, 230, 176)},
	{"name": "door_hall", "label": "Hall", "rect": Rect2(954, 70, 150, 515)},
]
const START_SPOT := 4  # the team comes in through the door, so the highlight starts there
const GIFT_RECT := Rect2(282, 300, 110, 110)  # the present, standing in the empty tub
const PIECE_RECT := Rect2(398, 352, 74, 60)   # a torn piece of the photo, beside it (spec 21)
const DIGIT_POSITION := Vector2(232, 318)     # the digit scratched into the enamel
const TURNS_POSITION := Vector2(650, 418)     # the turns so far, under the sink
const HIGHLIGHT := Color("ffd76a")
# Effects (spec 20)
const SOUNDS := "res://assets/sounds/"
const STEAM_RECT := Rect2(586, 92, 290, 226)  # over the mirror, a little larger
const MIRROR_SYMBOLS_RECT := Rect2(636, 176, 190, 70)  # the symbols, seen in the steamed mirror in the room
const TAP_SOUND_SECONDS := 1.5                # a turn plays only the start of the faucet
const FACE_SECONDS := 1.8  # long enough to be scary (second test round)

# The face in the mirror shows once per player and game run, not on every visit
# (the screen is made new each time the team walks in).
static var _face_seen := false

# -1 means: a new random game at every start. Tests set a fixed seed.
@export var seed_value := -1
# Offline only: start with the green fuse on (lit bathroom) or off (dark).
@export var green_fuse_on := true
var net: Node = null  # set by main.gd for online play

var game: Dictionary          # offline: our own game; online: the shared game
var _highlight := START_SPOT  # index in SPOTS

# Nodes we change later (built in _build_ui)
var _background: TextureRect
var _spot_buttons: Array[Button] = []
var _turns_label: Label
var _gift: TextureButton  # the present itself can be clicked to take it
var _piece: TextureButton  # a torn piece of the photo (spec 21)
var _digit_label: Label
var _mirror_panel: PanelContainer
var _mirror_dust: Label
var _mirror_symbols: HBoxContainer
var _symbol_images: Array[TextureRect] = []
var _message: Label
var _steam: TextureRect
var _mirror_steam: TextureRect
var _mirror_face: TextureRect
var _faucet: AudioStreamPlayer
var _scare: AudioStreamPlayer
var _rattle: AudioStreamPlayer  # spec 34: a wrong order
var _drain: AudioStreamPlayer
var _steam_hiss: AudioStreamPlayer

# Sounds this screen played (or would have played in the headless test run).
var sounds_played: Array[String] = []
var _keys_used := false  # the key frame only shows once someone uses the arrow keys
var _room_symbols: HBoxContainer        # the symbols in the steamed mirror, in the room
var _room_symbol_images: Array[TextureRect] = []
var _seen := {}  # what the shared game showed last time: turns, solved, penalty


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
	RoomStage.put_on_stage(self)  # click areas stay on their objects when the window changes (spec 21)


func _online() -> bool:
	return net != null and not net.game.is_empty()


# Offline: a real game from the rules, with the green fuse already on (or not).
func _offline_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var new_game := GameRules.new_game(rng)
	new_game["location"] = "bathroom"  # the team stands here (for the torn piece, spec 21)
	if green_fuse_on:
		var order: Array = new_game["puzzle"]["fuses"][GREEN_FUSE]["order"].duplicate()
		FuseRules.try_fuse(new_game["puzzle"], GREEN_FUSE, order)
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


func _bathroom() -> Dictionary:
	return game["bathroom"]


func _is_lit() -> bool:
	return "bathroom" in FuseRules.lit_rooms(game["puzzle"])


# ---------- keys ----------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_down"):
		_close_mirror()
	elif _mirror_panel.visible:
		return  # in the close-up only Esc / down does something
	elif event.is_action_pressed("ui_left"):
		_keys_used = true
		_move_highlight(-1)
	elif event.is_action_pressed("ui_right"):
		_keys_used = true
		_move_highlight(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up"):
		_use_spot(highlighted_spot())
	else:
		return
	accept_event_if_inside_tree()


func accept_event_if_inside_tree() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func highlighted_spot() -> String:
	return SPOTS[_highlight]["name"]


func _move_highlight(step: int) -> void:
	_set_highlight(clampi(_highlight + step, 0, SPOTS.size() - 1))


func _set_highlight(index: int) -> void:
	_highlight = index
	_refresh()


# ---------- using a spot (key or click) ----------

func _on_spot_pressed(index: int) -> void:
	_set_highlight(index)
	_use_spot(highlighted_spot())


func _use_spot(spot: String) -> void:
	match spot:
		"hot_tap":
			_turn_tap("hot")
		"cold_tap":
			_turn_tap("cold")
		"mirror":
			_open_mirror()
		"bathtub":
			_send("take_gift", {"room": "bathroom"})
		"door_hall":
			_send("go_to", {"place": "hall"})  # the whole team walks back (spec 07)


# Every turn goes to the shared game, so the whole team builds one order.
func _turn_tap(tap: String) -> void:
	if _bathroom()["solved"]:
		_message.text = "The taps are dry."
		return
	_send("turn_tap", {"tap": tap})


func _open_mirror() -> void:
	_mirror_panel.visible = true
	if not _face_seen:
		_face_seen = true
		_mirror_face.visible = true
		_mirror_dust.modulate.a = 0.0  # only the face, nothing else in the glass
		_play(_scare, "sfx_scare.mp3")
		_shake(_mirror_panel)
		get_tree().create_timer(FACE_SECONDS).timeout.connect(_face_goes)
	if not _bathroom()["solved"]:
		_message.text = "Too much dust to see anything... but something seems hidden underneath."
	_refresh()


func _close_mirror() -> void:
	_mirror_panel.visible = false
	_face_goes()


func _face_goes() -> void:
	_mirror_face.visible = false
	_mirror_dust.modulate.a = 1.0


# For tests: the next mirror visit shows the face again.
func forget_face() -> void:
	_face_seen = false


# ---------- effects (spec 20): sounds and steam ----------

func _what_happened_so_far() -> Dictionary:
	return {"turns": _bathroom()["turns"].size(), "solved": _bathroom()["solved"],
			"penalty": game.get("penalty_seconds", 0)}


# Something changed in the shared game (here or on a teammate's device): play what fits.
func _react() -> void:
	var now := _what_happened_so_far()
	if now["solved"] and not _seen["solved"]:
		_play(_drain, "sfx_drain.mp3")      # the tub drains ...
		_play(_steam_hiss, "sfx_steam.mp3") # ... and the steam hisses up the mirror
		_rise_steam()
	elif now["turns"] != _seen["turns"] or now["penalty"] > _seen["penalty"]:
		_play(_faucet, "sfx_faucet.mp3", 1.0, TAP_SOUND_SECONDS)
		if now["penalty"] > _seen["penalty"]:
			_play(_rattle, "sfx_key_lock.mp3", 0.7)  # spec 34: the pipes rattle angrily
	_seen = now


func _play(player: AudioStreamPlayer, file_name: String, pitch := 1.0, cut_after := 0.0) -> void:
	sounds_played.append(file_name)
	if DisplayServer.get_name() == "headless":
		return  # no sound card in the test run
	player.pitch_scale = pitch
	player.play()
	if cut_after > 0.0:
		get_tree().create_timer(cut_after).timeout.connect(player.stop)


# The steam fades in and drifts up a little over the mirror.
# A short, hard shake: the scare hits harder.
func _shake(node: Control) -> void:
	var home := node.position
	var tween := create_tween()
	for i in 8:
		var push := Vector2(randf_range(-10, 10), randf_range(-6, 6))
		tween.tween_property(node, "position", home + push, 0.04)
	tween.tween_property(node, "position", home, 0.05)


# The rhyme says "warm", so the screen does too (the rules keep "hot").
static func _tap_word(tap: String) -> String:
	return "warm" if tap == "hot" else tap


func _spot_index(spot_name: String) -> int:
	for i in SPOTS.size():
		if SPOTS[i]["name"] == spot_name:
			return i
	return -1


func _rise_steam() -> void:
	_steam.visible = true
	_steam.modulate.a = 0.0
	_steam.position = STEAM_RECT.position + Vector2(0, 30)
	var tween := create_tween().set_parallel()
	tween.tween_property(_steam, "modulate:a", 0.85, 1.5)
	tween.tween_property(_steam, "position", STEAM_RECT.position, 1.5)
	_room_symbols.modulate.a = 0.0  # the symbols show through the steam a moment later
	tween.tween_property(_room_symbols, "modulate:a", 0.85, 1.2).set_delay(0.8)


# ---------- showing the current state ----------

func _refresh() -> void:
	_background.texture = load(IMAGES + background_picture())

	# No frames on the picture: a frame only on hover, or on the spot the arrow keys chose.
	for i in _spot_buttons.size():
		var border := HIGHLIGHT if _keys_used and i == _highlight else Color(1, 1, 1, 0)
		_spot_buttons[i].add_theme_stylebox_override("normal", _spot_style(border))
	var solved_now: bool = _bathroom()["solved"]
	_spot_buttons[_spot_index("bathtub")].visible = not solved_now  # present and piece are clicked themselves

	# The turns made so far, in the rhyme's words ("warm  cold"); how many are needed stays a secret.
	var words := []
	for tap in _bathroom()["turns"]:
		words.append(tr(_tap_word(tap)))
	_turns_label.text = "  ".join(words)

	var solved: bool = _bathroom()["solved"]
	_gift.visible = solved and not _bathroom()["gift_taken"]
	_piece.visible = solved and not InventoryRules.has(game, "photo_piece_2") and not InventoryRules.has(game, "photo")
	_digit_label.visible = solved
	_digit_label.text = str(_bathroom()["digit"])

	_steam.visible = solved
	_mirror_steam.visible = solved
	_mirror_dust.visible = not solved
	_mirror_symbols.visible = solved
	_room_symbols.visible = solved  # in the room's mirror too, without clicking it
	var wheels: Array = game.get("bedroom", {}).get("wheels", EXAMPLE_WHEELS)
	var mirrored := BathroomRules.mirror_symbols(wheels)
	for i in _symbol_images.size():
		_symbol_images[i].texture = load(IMAGES + "sym_%s.png" % mirrored[i])
		_room_symbol_images[i].texture = _symbol_images[i].texture


# Dark until the green fuse is on, then lit with a full tub, then drained once solved.
func background_picture() -> String:
	if not _is_lit():
		return "room_bathroom_dark.webp"
	if _bathroom()["solved"]:
		return "room_bathroom_drained.webp"
	return "room_bathroom_lit.webp"


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
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_background)

	# The tub after solving: the present and the digit (the water is in the picture).
	_gift = TextureButton.new()
	_gift.name = "Gift"
	_gift.texture_normal = load(IMAGES + "item_gift_2.png")
	_gift.ignore_texture_size = true
	_gift.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_gift.tooltip_text = "Take the present"
	_gift.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	HoverGlow.item(_gift)
	_gift.pressed.connect(func() -> void: _send("take_gift", {"room": "bathroom"}))
	_gift.position = GIFT_RECT.position
	_gift.size = GIFT_RECT.size
	add_child(_gift)
	_piece = TextureButton.new()
	_piece.name = "PhotoPiece"
	_piece.texture_normal = load(IMAGES + "item_photo_piece_2.png")
	_piece.ignore_texture_size = true
	_piece.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_piece.position = PIECE_RECT.position
	_piece.size = PIECE_RECT.size
	_piece.rotation_degrees = -12  # lying a little crooked in the tub
	_piece.tooltip_text = "A torn piece of paper"
	_piece.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	HoverGlow.item(_piece)
	_piece.pressed.connect(func() -> void: _send("take_piece", {"room": "bathroom"}))
	add_child(_piece)
	_digit_label = _label(self, "", 44)
	_digit_label.name = "DigitLabel"
	_digit_label.position = DIGIT_POSITION
	_digit_label.add_theme_color_override("font_color", Color("4caf50"))
	_digit_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_digit_label.add_theme_constant_override("outline_size", 8)

	# Steam over the mirror once the taps are solved (spec 20).
	_steam = _picture("Steam", "prop_steam.png", STEAM_RECT)
	# The symbols show through the steam on the mirror, as soon as the taps are right.
	_room_symbols = HBoxContainer.new()
	_room_symbols.name = "RoomMirrorSymbols"
	_room_symbols.alignment = BoxContainer.ALIGNMENT_CENTER
	_room_symbols.add_theme_constant_override("separation", 10)
	_room_symbols.position = MIRROR_SYMBOLS_RECT.position
	_room_symbols.size = MIRROR_SYMBOLS_RECT.size
	_room_symbols.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room_symbols.modulate = Color(1, 1, 1, 0.85)
	add_child(_room_symbols)
	for i in 3:
		var symbol := TextureRect.new()
		symbol.name = "RoomMirrorSymbol%d" % i
		symbol.custom_minimum_size = Vector2(52, 52)
		symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		symbol.flip_h = true  # a mirror shows each symbol the wrong way round
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_room_symbols.add_child(symbol)
		_room_symbol_images.append(symbol)
	_steam.modulate.a = 0.85

	# The spots: see-through buttons over the picture, with a name.
	for i in SPOTS.size():
		var spot: Dictionary = SPOTS[i]
		var button := Button.new()
		button.name = "Spot_" + spot["name"]
		# Spec 21: no names on the objects, except the taps; the name shows on hover.
		button.text = spot["label"] if spot["name"] in ["hot_tap", "cold_tap"] else ""
		button.tooltip_text = spot["label"]
		button.position = spot["rect"].position
		button.size = spot["rect"].size
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_outline_color", Color.BLACK)
		button.add_theme_constant_override("outline_size", 5)
		HoverGlow.spot(button)  # a soft gold glow on hover (spec 34)
		button.pressed.connect(_on_spot_pressed.bind(i))
		add_child(button)
		_spot_buttons.append(button)

	# The turns so far, under the sink.
	_turns_label = _label(self, "", 22)
	_turns_label.name = "TurnsLabel"
	_turns_label.position = TURNS_POSITION
	_turns_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_turns_label.add_theme_constant_override("outline_size", 6)

	# Title and message line.
	var title := _label(self, "The Bathroom", 34)
	title.position = Vector2(52, 12)  # right of the music button (spec 33)
	title.add_theme_color_override("font_color", Color("e8d9c0"))
	_message = _label(self, "", 22)
	_message.name = "Message"
	# Playtest (Lara): ends before the inventory bar (bottom right) and wraps instead.
	_message.position = Vector2(24, 548)
	_message.size = Vector2(660, 88)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_message.add_theme_color_override("font_color", Color("ffd76a"))

	# The mirror close-up: dust before solving, the mirrored symbols after.
	_mirror_panel = PanelContainer.new()
	_mirror_panel.name = "MirrorPanel"
	_mirror_panel.visible = false
	_mirror_panel.position = Vector2(326, 120)
	_mirror_panel.size = Vector2(500, 360)
	_mirror_panel.add_theme_stylebox_override("panel", _box(Color("b9c4c8"), Color("5c4a3a")))
	add_child(_mirror_panel)
	# Behind the symbols: steam (after solving). On top: the face, for half a second.
	_mirror_steam = TextureRect.new()
	_mirror_steam.name = "MirrorSteam"
	_mirror_steam.texture = load(IMAGES + "prop_steam.png")
	_mirror_steam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mirror_steam.stretch_mode = TextureRect.STRETCH_SCALE
	_mirror_steam.modulate.a = 0.7
	_mirror_steam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mirror_panel.add_child(_mirror_steam)
	var mirror_content := VBoxContainer.new()
	mirror_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_mirror_panel.add_child(mirror_content)
	# A hint that the mirror will matter later: the steam from the hot water clears it.
	_mirror_dust = _label(mirror_content, "Grey dust covers the glass.\nFaint marks hide underneath...\nPerhaps turning the taps in the right order will clear the view.", 22)
	_mirror_dust.name = "MirrorDust"
	_mirror_dust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mirror_dust.add_theme_color_override("font_color", Color("4a4a4a"))
	_mirror_symbols = HBoxContainer.new()
	_mirror_symbols.name = "MirrorSymbols"
	_mirror_symbols.alignment = BoxContainer.ALIGNMENT_CENTER
	_mirror_symbols.add_theme_constant_override("separation", 24)
	mirror_content.add_child(_mirror_symbols)
	for i in 3:
		var symbol := TextureRect.new()
		symbol.name = "MirrorSymbol%d" % i
		symbol.custom_minimum_size = Vector2(110, 110)
		symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		symbol.flip_h = true  # a mirror shows each symbol the wrong way round
		symbol.modulate = Color(1, 1, 1, 0.8)  # seen through the steam
		_mirror_symbols.add_child(symbol)
		_symbol_images.append(symbol)
	var hint := _label(mirror_content, "Esc: back", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("4a4a4a"))
	_mirror_face = TextureRect.new()
	_mirror_face.name = "MirrorFace"
	_mirror_face.texture = load(IMAGES + "prop_mirror_face.png")
	_mirror_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mirror_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mirror_face.visible = false
	_mirror_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mirror_panel.add_child(_mirror_face)

	_faucet = _sound("Faucet", "sfx_faucet.mp3")
	_scare = _sound("Scare", "sfx_scare.mp3")
	_drain = _sound("Drain", "sfx_drain.mp3")
	_steam_hiss = _sound("SteamHiss", "sfx_steam.mp3")
	_rattle = _sound("Rattle", "sfx_key_lock.mp3")


func _picture(node_name: String, file: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = load(IMAGES + file)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.position = rect.position
	picture.size = rect.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	return picture


func _sound(node_name: String, file_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = load(SOUNDS + file_name)
	add_child(player)
	return player


func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _spot_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(6)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(24)
	return style
