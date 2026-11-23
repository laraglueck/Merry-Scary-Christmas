# The view out of the living room and bedroom windows (spec 26): the front garden through the
# window, with the full moon in the sky behind the trees (view_window_garden.png, made by
# tools/make_window_view.gd), and the real weather in Nuuk (Greenland) now, from Open-Meteo.
# First the frost is wiped off the glass, from left to right (Settings.WINDOW_WIPE_SECONDS),
# then the weather shows; an answer that comes earlier waits for the wipe.
# No answer in time (no internet, the service is down): the fallback, and it snows anyway.
# Only on this device; it costs no time and changes nothing. Esc, Enter or a click closes it.
extends Control

signal closed

const WeatherRules = preload("res://scripts/rules/weather_rules.gd")
const Settings = preload("res://scripts/settings.gd")
const Title = preload("res://scripts/title.gd")

const IMAGES := "res://assets/images/"
const OPENING := Rect2(226, 24, 700, 516)       # the glass on the 1152 x 648 stage (same shape as the picture)
const FRAME := 18.0                             # the wooden frame around the glass
const BAR := 12.0                               # the window bars
const WOOD := Color("3a2a1e")
const STORY_TEXT := "Somewhere out there, Santa's sleigh is flying tonight. Without Jingles."
const WAITING_TEXT := "Wiping the frost off the glass..."
const CLEAR_PICTURE := "view_window_garden.png"         # bright moon
const CLOUDY_PICTURE := "view_window_garden_cloudy.png"  # pale moon behind clouds
const CLOUDY_KINDS := ["cloudy", "fog"]  # rain and storm keep the bright moon, like snow
const WEATHER_SOUNDS := {
	"rain": preload("res://assets/sounds/sfx_rain.mp3"),
	"storm": preload("res://assets/sounds/sfx_storm.mp3"),
}
const FROST := Color(0.82, 0.87, 0.93, 0.9)
const FROST_EDGE := 80.0  # the soft edge of the frost, where the cloth is

## How far the glass is wiped clear: 0 = all frost, 1 = clear (the tween moves it).
var wipe := 0.0:
	set(value):
		wipe = clampf(value, 0.0, 1.0)
		if _frost != null:
			_frost.position.x = OPENING.size.x * wipe - FROST_EDGE
			_frost.size.x = OPENING.size.x * (1.0 - wipe) + FROST_EDGE

var _weather_line: Label
var _garden: TextureRect
var _snow: CPUParticles2D
var _storm: CPUParticles2D
var _rain: CPUParticles2D
var _mist: ColorRect
var _tint: ColorRect
var _weather_audio: AudioStreamPlayer
var _audible_weather := ""
var _request: HTTPRequest
var _frost: Control
var _wipe_tween: Tween
var _wipe_done := false
var _waiting := {}  # the weather that came while the glass was still frosty


func _ready() -> void:
	name = "WindowView"
	add_to_group("hides_inventory")  # main.gd hides this device's inventory meanwhile (spec 29)
	_tell_the_hud()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # added after the room is built: fill it
	mouse_filter = Control.MOUSE_FILTER_STOP  # a click anywhere closes the view
	_build()
	_weather_audio = AudioStreamPlayer.new()
	_weather_audio.name = "WeatherAudio"
	add_child(_weather_audio)
	wipe = 0.0
	_wipe_tween = create_tween()
	_wipe_tween.tween_property(self, "wipe", 1.0, Settings.WINDOW_WIPE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wipe_tween.finished.connect(finish_wipe)
	if DisplayServer.get_name() == "headless":
		show_weather(WeatherRules.fallback())  # the tests ask no service; they feed answers directly
	else:
		_ask_the_service()


# The weather outside: shown once the glass is wiped (until then it waits).
func show_weather(weather: Dictionary) -> void:
	if _wipe_done:
		_show_now(weather)
	else:
		_waiting = weather


# The glass is clear: the weather that came meanwhile shows now (or as soon as it comes).
func finish_wipe() -> void:
	if _wipe_done:
		return
	_wipe_done = true
	if _wipe_tween != null and _wipe_tween.is_valid():
		_wipe_tween.kill()
	wipe = 1.0
	_frost.visible = false
	if not _waiting.is_empty():
		_show_now(_waiting)


# Particles or mist, and the line under the window.
func _show_now(weather: Dictionary) -> void:
	var kind: String = weather.get("kind", "snow")
	_garden.texture = load(IMAGES + (CLOUDY_PICTURE if kind in CLOUDY_KINDS else CLEAR_PICTURE))
	_snow.emitting = kind == "snow"
	_snow.visible = _snow.emitting
	_storm.emitting = kind == "storm"
	_storm.visible = _storm.emitting
	_rain.emitting = kind == "rain"
	_rain.visible = _rain.emitting
	_mist.visible = kind in ["cloudy", "fog", "storm"]
	_mist.color.a = 0.45 if kind == "fog" else 0.25
	_tint.visible = kind in ["rain", "storm"]  # a darker, heavier sky
	_weather_line.text = weather.get("text", WeatherRules.FALLBACK_TEXT)
	_set_weather_audio(kind)


func _set_weather_audio(kind: String) -> void:
	if kind == _audible_weather:
		return
	_audible_weather = kind
	_weather_audio.stop()
	var clip: AudioStreamMP3 = WEATHER_SOUNDS.get(kind)
	if clip == null:
		_weather_audio.stream = null
		return
	var looped := clip.duplicate() as AudioStreamMP3
	looped.loop = true
	_weather_audio.stream = looped
	_weather_audio.volume_db = -22.0 if kind == "rain" else -17.0
	if DisplayServer.get_name() != "headless":
		_weather_audio.play()
		_weather_audio.stream_paused = not _weather_audio.can_process()


func _ask_the_service() -> void:
	_request = HTTPRequest.new()
	_request.name = "WeatherRequest"
	_request.timeout = Settings.WEATHER_TIMEOUT_SECONDS
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	if _request.request(WeatherRules.url()) != OK:
		show_weather(WeatherRules.fallback())


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		show_weather(WeatherRules.from_response(body.get_string_from_utf8()))
	else:
		show_weather(WeatherRules.fallback())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if _request != null:
		_request.cancel_request()
	_set_weather_audio("")
	visible = false
	remove_from_group("hides_inventory")
	_tell_the_hud()
	closed.emit()
	queue_free()


# Also when the screen changes while the view is open.
func _exit_tree() -> void:
	if is_in_group("hides_inventory"):
		remove_from_group("hides_inventory")
		_tell_the_hud()


func _tell_the_hud() -> void:
	get_tree().call_group("hud_owner", "refresh_hud")


# ---------- building the view (runs once) ----------

func _build() -> void:
	var wall := ColorRect.new()  # the dark room around the window
	wall.color = Color("120b0c")
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)

	var glass := Control.new()  # everything outside is cut off at the glass
	glass.name = "Glass"
	glass.position = OPENING.position
	glass.size = OPENING.size
	glass.clip_contents = true
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glass)
	_garden = TextureRect.new()
	_garden.name = "GardenView"
	_garden.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # first, then the size
	_garden.stretch_mode = TextureRect.STRETCH_SCALE
	_garden.texture = load(IMAGES + CLEAR_PICTURE)
	_garden.size = OPENING.size
	_garden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.add_child(_garden)
	_tint = ColorRect.new()
	_tint.name = "WeatherTint"
	_tint.color = Color(0.04, 0.07, 0.15, 0.4)
	_tint.size = OPENING.size
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.visible = false
	glass.add_child(_tint)
	_mist = ColorRect.new()
	_mist.name = "WeatherMist"
	_mist.color = Color(0.72, 0.76, 0.84, 0.25)
	_mist.size = OPENING.size
	_mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.add_child(_mist)
	_snow = Title.make_snow(OPENING.size.x)
	_snow.name = "WeatherSnow"
	glass.add_child(_snow)
	_rain = _make_rain(OPENING.size.x)
	glass.add_child(_rain)
	_storm = _make_storm(OPENING.size)
	glass.add_child(_storm)
	_snow.emitting = false  # the weather shows after the wipe
	_snow.visible = false
	_mist.visible = false

	# The frost on the glass: solid, with a soft edge where it is being wiped away.
	_frost = Control.new()
	_frost.name = "Frost"
	_frost.size = Vector2(OPENING.size.x + FROST_EDGE, OPENING.size.y)
	_frost.clip_contents = true
	_frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.add_child(_frost)
	var edge := TextureRect.new()
	var fade := GradientTexture2D.new()
	fade.gradient = Gradient.new()
	fade.gradient.set_color(0, Color(FROST, 0.0))
	fade.gradient.set_color(1, FROST)
	fade.width = int(FROST_EDGE)
	fade.height = 4
	edge.texture = fade
	edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge.stretch_mode = TextureRect.STRETCH_SCALE
	edge.size = Vector2(FROST_EDGE, OPENING.size.y)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost.add_child(edge)
	var ice := ColorRect.new()
	ice.color = FROST
	ice.position = Vector2(FROST_EDGE, 0)
	ice.size = OPENING.size
	ice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost.add_child(ice)

	# The window frame with its bars, and the sill.
	for rect in [Rect2(-FRAME, -FRAME, OPENING.size.x + 2 * FRAME, FRAME),
			Rect2(-FRAME, OPENING.size.y, OPENING.size.x + 2 * FRAME, FRAME),
			Rect2(-FRAME, 0, FRAME, OPENING.size.y), Rect2(OPENING.size.x, 0, FRAME, OPENING.size.y),
			Rect2(OPENING.size.x / 2 - BAR / 2, 0, BAR, OPENING.size.y),
			Rect2(0, OPENING.size.y * 0.45 - BAR / 2, OPENING.size.x, BAR),
			Rect2(-FRAME - 20, OPENING.size.y + FRAME, OPENING.size.x + 2 * FRAME + 40, 12)]:
		var wood := ColorRect.new()
		wood.color = WOOD
		wood.position = OPENING.position + rect.position
		wood.size = rect.size
		wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(wood)

	_weather_line = _line("WeatherLine", WAITING_TEXT, 24, Color("ffd76a"), 570)
	_line("StoryLine", STORY_TEXT, 20, Color("e8d9c0"), 606)
	var hint := _line("BackHint", "Click to step back", 14, Color(0.91, 0.85, 0.75, 0.5), 628)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _line(node_name: String, text: String, size: int, colour: Color, y: float) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(24, y)
	label.size = Vector2(1104, 30)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


# Rain: fast, slightly slanted streaks (a thin line that points the way it falls).
static func _make_rain(width: float) -> CPUParticles2D:
	var streak := GradientTexture2D.new()
	streak.gradient = Gradient.new()
	streak.gradient.set_color(0, Color(1, 1, 1, 0.0))
	streak.gradient.set_color(1, Color(1, 1, 1, 0.9))
	streak.fill_from = Vector2(0.5, 0.0)  # see-through at the tail, bright at the head
	streak.fill_to = Vector2(0.5, 1.0)
	streak.width = 2
	streak.height = 26
	var rain := CPUParticles2D.new()
	rain.name = "WeatherRain"
	rain.texture = streak
	rain.particle_flag_align_y = true
	rain.amount = 320
	rain.lifetime = 0.7
	rain.preprocess = 0.7
	rain.position = Vector2(width / 2.0, -30)
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(width / 2.0 + 80, 1)
	rain.direction = Vector2(0.15, 1)
	rain.spread = 2.0
	rain.gravity = Vector2(0, 900)
	rain.initial_velocity_min = 650.0
	rain.initial_velocity_max = 850.0
	rain.color = Color(0.8, 0.88, 1.0, 0.7)
	rain.emitting = false
	return rain


# Storm: dense snow, blown sideways by the wind.
static func _make_storm(area: Vector2) -> CPUParticles2D:
	var storm := CPUParticles2D.new()
	storm.name = "WeatherStorm"
	storm.amount = 420
	storm.lifetime = 2.2
	storm.preprocess = 2.2
	storm.position = Vector2(area.x / 2.0 - 260, -20)
	storm.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	storm.emission_rect_extents = Vector2(area.x / 2.0 + 260, 1)
	storm.direction = Vector2(1, 0.5)
	storm.spread = 15.0
	storm.gravity = Vector2(260, 90)
	storm.initial_velocity_min = 180.0
	storm.initial_velocity_max = 320.0
	storm.scale_amount_min = 1.5
	storm.scale_amount_max = 3.2
	storm.color = Color(1, 1, 1, 0.85)
	storm.emitting = false
	return storm
