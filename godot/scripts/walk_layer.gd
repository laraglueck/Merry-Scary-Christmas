# The walking layer (spec 19): shows the figures of the shared game in a room and walks the
# own figure with the keys W A S D (up = into the room, down = towards you). Used by the
# rooms; a room adds it over its picture (a child of the picture area) and needs nothing else.
# Everything is measured in pixels of the room picture (1376 x 768) and scales with it.
# The host decides where the figures are (walk_rules.gd, network.gd); this script only shows
# net.game["figures"] and sends "move" when the pressed keys change. Positions arrive about
# 10 times a second, so each figure glides to the place it was told, which looks smooth.
# Far away = smaller; the figure further back is drawn first, so the nearer one covers it.
extends Control

const Settings = preload("res://scripts/settings.gd")
const CharacterRules = preload("res://scripts/rules/character_rules.gd")
const WalkRules = preload("res://scripts/rules/walk_rules.gd")

const IMAGES := "res://assets/images/"
const PICTURE_SIZE := Vector2(1376, 768)
const FIGURE_HEIGHT := 330.0    # the figure's height at the front of the floor, in picture pixels
const GLIDE_SPEED := 1.6        # a little faster than walking, so the picture catches up

var net: Node = null  # handed in by the room

var _figures := {}   # player -> its picture
var _shown := {}     # player -> where it is drawn right now (picture pixels, the feet)
var _held := {}      # physical key -> true while pressed (W, A, S, D)
var _sent := Vector2.ZERO
var _outline: Control  # F3: the floor as a red outline over the picture, to check the walls


func _ready() -> void:
	name = "WalkLayer"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for player in net.game.get("figures", {}):
		var figure := TextureRect.new()
		figure.name = "Figure_%d" % player
		figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(figure)
		_figures[player] = figure
		_shown[player] = _place_of(player, Vector2.ZERO)
	_outline = Control.new()
	_outline.name = "FloorOutline"
	_outline.set_anchors_preset(Control.PRESET_FULL_RECT)
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.z_index = 2000
	_outline.visible = false
	_outline.draw.connect(_draw_outline)
	add_child(_outline)
	net.game_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var game: Dictionary = net.game
	for player in _figures:
		var look := _look(game, player)
		_figures[player].texture = load(IMAGES + CharacterRules.picture_file(look["character"], look["colour"]))
	_place_figures(0.0)


# The chosen figure of the player; a game without a selection gets the standard figures:
# Santa, snowman, nutcracker in their colours.
func _look(game: Dictionary, player: int) -> Dictionary:
	var chosen: Dictionary = game.get("characters", {}).get(player, {})
	if not chosen.is_empty():
		return chosen
	return {"character": Settings.CHARACTERS[player]["id"], "colour": Settings.CHARACTER_COLOURS[player]["id"]}


func _place_of(player: int, fallback: Vector2) -> Vector2:
	var figure: Dictionary = net.game.get("figures", {}).get(player, {})
	return Vector2(figure["x"], figure["y"]) if not figure.is_empty() else fallback


func _process(delta: float) -> void:
	_place_figures(delta)


# Glide each figure towards the host's place and put it on the screen.
func _place_figures(delta: float) -> void:
	var factor := size.x / PICTURE_SIZE.x
	for player in _figures:
		var wanted := _place_of(player, _shown[player])
		_shown[player] = _shown[player].move_toward(wanted, Settings.WALK_SPEED * GLIDE_SPEED * delta) if delta > 0.0 else wanted
		var figure: TextureRect = _figures[player]
		var picture_size: Vector2 = figure.texture.get_size() if figure.texture != null else Vector2(1, 1)
		var height := FIGURE_HEIGHT * WalkRules.depth_scale(net.game.get("location", "hall"), _shown[player].y)
		var width := height * picture_size.x / picture_size.y
		figure.size = Vector2(width, height) * factor
		figure.position = Vector2(_shown[player].x - width / 2.0, _shown[player].y - height) * factor
		figure.z_index = int(_shown[player].y)  # nearer figures cover the ones behind them


# ---------- the floor outline (F3) ----------

func _draw_outline() -> void:
	var factor := size.x / PICTURE_SIZE.x
	var points := PackedVector2Array()
	for point in WalkRules.floor_polygon(net.game.get("location", "hall")):
		points.append(point * factor)
	points.append(points[0])
	_outline.draw_polyline(points, Color(1, 0.2, 0.2), 3.0)


# ---------- the keys ----------

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	if key.physical_keycode == KEY_F3 and key.pressed:
		_outline.visible = not _outline.visible
		_outline.queue_redraw()
		return
	if key.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_held[key.physical_keycode] = key.pressed
		_send_direction()


# The window lost the focus: all keys count as released, so the figure does not walk on.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_held.clear()
		_send_direction()


func _send_direction() -> void:
	var direction := Vector2(
		(1.0 if _held.get(KEY_D, false) else 0.0) - (1.0 if _held.get(KEY_A, false) else 0.0),
		(1.0 if _held.get(KEY_S, false) else 0.0) - (1.0 if _held.get(KEY_W, false) else 0.0))
	if direction == _sent:
		return
	_sent = direction
	net.send_action("move", {"dx": direction.x, "dy": direction.y})
