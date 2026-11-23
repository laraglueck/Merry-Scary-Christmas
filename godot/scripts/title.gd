# The title screen (spec 11): the house in the snow with Santa, the snowman and the
# nutcracker in front of it, a flickering light in the window, falling snow, quiet
# wind, the game name and "Start". The music comes from main.gd, the story from the
# loading screen before (spec 12).
# Shown on every device on its own before the lobby; nothing here goes over the network.
# main.gd listens to start_pressed and then shows the lobby. Started alone (⌘ R),
# "Start" does nothing.
extends Control

signal start_pressed

const Hall = preload("res://scripts/hall.gd")
const Settings = preload("res://scripts/settings.gd")
const Comfort = preload("res://scripts/comfort.gd")

const IMAGES := "res://assets/images/"
const SOUNDS := "res://assets/sounds/"

# Everything on the "stage" is placed in pixels of the house picture (ui_title.webp).
# The stage is scaled to cover the window, so the places stay right at any size.
const STAGE_SIZE := Vector2(1376, 768)
const WINDOW_RECT := Rect2(780, 291, 47, 78)    # the glass of the lit window, with its glowing edge
const WINDOW_GLASS_DARK := Color("1d2230")      # the glass when the light is off
const GLOW_CENTRE := Vector2(803, 345)          # warm light around the window
const GLOW_RADIUS := 150.0
const GLOW_COLOUR := Color(1.0, 0.78, 0.35, 0.35)

# Figures: picture, where its feet stand (centre bottom), height on the stage.
const FIGURES := [
	{"name": "Nutcracker", "file": "char_nutcracker.png", "feet": Vector2(985, 745), "height": 320.0},
	{"name": "Santa", "file": "char_santa.png", "feet": Vector2(330, 760), "height": 420.0},
	{"name": "Snowman", "file": "char_snowman.png", "feet": Vector2(1140, 758), "height": 350.0},
]
const NIGHT_TINT := Color(0.78, 0.8, 0.92)  # figures a little bluer and darker, like the night

const TITLE_CREAM := Color("efe2c8")
const BLOOD_RED := Color("8b1a1a")
const NIGHT := Color("0b0d14")

var net: Node = null  # main.gd hands this in like for every screen; the title doesn't need it

var _stage: Control
var _window_dark: ColorRect
var _window_glow: TextureRect
var _flicker_rng := RandomNumberGenerator.new()
var _flicker_steps: Array = []
var _flicker_timer: Timer


func _ready() -> void:
	_build_ui()
	_add_sound("Wind", "sfx_wind.mp3", true, -14.0)
	resized.connect(_fit_stage)
	_fit_stage()
	_flicker_rng.randomize()
	_flicker_timer = Timer.new()
	_flicker_timer.one_shot = true
	_flicker_timer.timeout.connect(func(): _flicker_timer.start(flicker_step()))
	add_child(_flicker_timer)
	_flicker_timer.start(0.5)


func _on_start_pressed() -> void:
	start_pressed.emit()


# ---------- the flickering window (reuses the hall's loose-bulb rhythm, spec 05) ----------

# Shows the next step of the flicker and returns how long it lasts (seconds).
func flicker_step() -> float:
	if Comfort.reduce_flashing:  # spec 34: the window light stays steadily dim
		_flicker_steps.clear()
		_window_dark.color.a = 0.4
		_window_glow.modulate.a = 0.6
		return 0.5
	if _flicker_steps.is_empty():
		_flicker_steps = Hall.flicker_cycle(_flicker_rng, Settings.TITLE_FLICKER_DARKNESS)
	var step: Array = _flicker_steps.pop_front()
	var darkness: float = step[0]
	_window_dark.color.a = darkness
	_window_glow.modulate.a = 1.0 - darkness
	return step[1]


# The stage covers the whole screen and stays centred, like the picture would.
func _fit_stage() -> void:
	if _stage == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := maxf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	_stage.scale = Vector2(factor, factor)
	_stage.position = (size - STAGE_SIZE * factor) / 2.0


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var night := ColorRect.new()  # shows while the picture loads, and around it
	night.color = NIGHT
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(night)

	_stage = Control.new()
	_stage.name = "Stage"
	_stage.size = STAGE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load(IMAGES + "ui_title.webp")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = STAGE_SIZE
	_stage.add_child(background)

	_window_dark = ColorRect.new()
	_window_dark.name = "WindowDark"
	_window_dark.color = Color(WINDOW_GLASS_DARK, 0.0)
	_window_dark.position = WINDOW_RECT.position
	_window_dark.size = WINDOW_RECT.size
	_stage.add_child(_window_dark)

	_window_glow = TextureRect.new()
	_window_glow.name = "WindowGlow"
	_window_glow.texture = radial(GLOW_COLOUR, Color(GLOW_COLOUR, 0.0))
	_window_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_window_glow.size = Vector2(GLOW_RADIUS, GLOW_RADIUS) * 2.0
	_window_glow.position = GLOW_CENTRE - Vector2(GLOW_RADIUS, GLOW_RADIUS)
	var add_light := CanvasItemMaterial.new()
	add_light.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_window_glow.material = add_light
	_stage.add_child(_window_glow)

	_stage.add_child(make_snow(STAGE_SIZE.x))

	for figure: Dictionary in FIGURES:
		_stage.add_child(_figure(figure))

	var vignette := TextureRect.new()  # dark edges: spooky, and the eye goes to the window
	vignette.name = "Vignette"
	vignette.texture = radial(Color(NIGHT, 0.0), Color(NIGHT, 0.85), 0.45)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	add_child(page)

	var top_space := Control.new()
	top_space.custom_minimum_size = Vector2(0, 28)
	page.add_child(top_space)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Merry Scary Christmas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", TITLE_CREAM)
	title.add_theme_color_override("font_outline_color", NIGHT)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_shadow_color", BLOOD_RED)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	page.add_child(title)

	var middle := Control.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(middle)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.custom_minimum_size = Vector2(240, 60)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 28)
	start.add_theme_color_override("font_color", TITLE_CREAM)
	start.add_theme_color_override("font_hover_color", Color.WHITE)
	start.add_theme_stylebox_override("normal", _button_box(BLOOD_RED.darkened(0.25)))
	start.add_theme_stylebox_override("hover", _button_box(BLOOD_RED))
	start.add_theme_stylebox_override("pressed", _button_box(BLOOD_RED.darkened(0.45)))
	start.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start.pressed.connect(_on_start_pressed)
	page.add_child(start)

	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 36)
	page.add_child(bottom_space)


# A figure stands with its feet on the given spot, scaled to the given height.
func _figure(figure: Dictionary) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = figure["name"]
	picture.texture = load(IMAGES + figure["file"])
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.modulate = NIGHT_TINT
	var picture_size: Vector2 = picture.texture.get_size()
	var height: float = figure["height"]
	picture.size = Vector2(picture_size.x * height / picture_size.y, height)
	picture.position = figure["feet"] - Vector2(picture.size.x / 2.0, height)
	return picture


# Slowly falling snow over the given width (also used by the loading screen).
static func make_snow(width: float) -> CPUParticles2D:
	var snow := CPUParticles2D.new()
	snow.name = "Snow"
	snow.amount = 160
	snow.lifetime = 9.0
	snow.preprocess = 9.0  # already snowing when the screen opens
	snow.position = Vector2(width / 2.0, -10)
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(width / 2.0 + 80, 1)
	snow.direction = Vector2(0.25, 1)
	snow.spread = 12.0
	snow.gravity = Vector2(0, 6)
	snow.initial_velocity_min = 40.0
	snow.initial_velocity_max = 75.0
	snow.scale_amount_min = 1.5
	snow.scale_amount_max = 3.5
	snow.color = Color(1, 1, 1, 0.75)
	return snow


# A round gradient from the centre colour to the edge colour (also used by the loading screen).
static func radial(centre: Color, edge: Color, inner := 0.0) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, centre)
	gradient.set_color(1, edge)
	if inner > 0.0:
		gradient.add_point(inner, centre)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture


func _button_box(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.border_color = TITLE_CREAM.darkened(0.3)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.6)
	box.shadow_size = 8
	return box


func _add_sound(node_name: String, file_name: String, looping: bool, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	var stream: AudioStreamMP3 = load(SOUNDS + file_name)
	stream.loop = looping
	player.stream = stream
	player.volume_db = volume_db
	# Plays by itself in the real game. Not in the headless test run: there is no sound
	# card there, and a sound still playing at the end shows up as a leak warning.
	player.autoplay = DisplayServer.get_name() != "headless"
	add_child(player)
