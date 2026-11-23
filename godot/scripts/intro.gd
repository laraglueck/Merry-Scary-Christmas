# The loading screen (spec 12): a dark night with falling snow, the story read out
# (voice_title.mp3) and shown as subtitles, one line after the other. When the voice
# ends, or on a click or key, it sends `finished`; main.gd then shows the title
# (spec 25: the story comes first on each device, before the title).
# Spec 23: no music under the story any more (main.gd plays it on the title only).
extends Control

signal finished

const Title = preload("res://scripts/title.gd")

const SOUNDS := "res://assets/sounds/"

# The story, exactly as the voice reads it, one subtitle per entry, and the second
# in voice_title.mp3 where each line starts. Change both lists together.
const STORY_LINES := [
	"Once I was Santa's most loyal helper.",
	"I had one job: deliver the presents on Christmas Eve.",
	"Then the storm came. I was stuck in the snow, and couldn't deliver the presents.",
	"The children woke up to empty stockings, and Santa Claus fired me.",
	"Now I live alone in this old house, and I hate Christmas.",
	"Every Christmas Eve, I take my revenge.",
	"Three presents, stolen and hidden somewhere in these walls.",
	"Think you can find them before the time runs out?",
]
const LINE_START_SECONDS := [0.0, 5.0, 9.0, 15.0, 19.0, 23.0, 27.0, 31.0]

# Only these keys skip the story. Not "any key": a Mac's volume keys arrive as key
# presses too, and turning the sound up must not skip what you want to hear.
const SKIP_KEYS := [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]

const FADE_SECONDS := 0.35        # a subtitle fades in and out this fast
const EXTRA_WAIT_SECONDS := 1.5   # without sound, go on this long after the voice's length
const SUBTITLE_WIDTH := 1060.0    # fixed width, so the label can wrap (see TEAM-GUIDE pitfalls)

var net: Node = null  # main.gd hands this in like for every screen; the intro doesn't need it
var elapsed := 0.0
# Spec 23: seconds of fading in from black before the voice starts (main.gd sets it for the
# story in the game, so it does not start too suddenly). 0 = start at once, as before.
var lead_in := 0.0
var voice_started := false
# Spec 34: a browser plays no sound before the first click on the page, so there the story
# waits behind "Click to start"; that click starts it (and unlocks the sound).
var wait_for_click := OS.has_feature("web")

var _fade: ColorRect
var _click_to_start: Label

var _voice: AudioStreamPlayer
var _subtitle: Label
var _length := 0.0
var _done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # a click anywhere skips
	_build_ui()
	_voice = AudioStreamPlayer.new()
	_voice.name = "Voice"
	var stream: AudioStreamMP3 = load(SOUNDS + "voice_title.mp3")
	stream.loop = false
	_voice.stream = stream
	# Plays by itself in the real game. Not in the headless test run: there is no sound
	# card there, and a sound still playing at the end shows up as a leak warning.
	_voice.autoplay = DisplayServer.get_name() != "headless" and lead_in <= 0.0 and not wait_for_click
	voice_started = lead_in <= 0.0 and not wait_for_click
	elapsed = -lead_in  # below 0: still fading in, the story starts at 0
	_voice.finished.connect(_finish)
	add_child(_voice)
	_length = stream.get_length()
	_show_subtitle()


func _process(delta: float) -> void:
	advance(delta)


# Moves the story clock on (the tests call this to fast-forward).
func advance(seconds: float) -> void:
	if _done or wait_for_click:
		return  # spec 34: in the browser nothing moves before the first click
	elapsed += seconds
	if lead_in > 0.0:
		_fade.color.a = clampf(-elapsed / lead_in, 0.0, 1.0)
	if not voice_started and elapsed >= 0.0:
		voice_started = true
		if DisplayServer.get_name() != "headless":
			_voice.play()  # not in the test run: no sound card
	_show_subtitle()
	if elapsed > _length + EXTRA_WAIT_SECONDS:
		_finish()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_start_or_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and SKIP_KEYS.has(event.keycode):
		_start_or_finish()


# Spec 34: in the browser the first click starts the story; every other one skips it.
func _start_or_finish() -> void:
	if wait_for_click:
		wait_for_click = false
		_click_to_start.visible = false
		elapsed = maxf(elapsed, 0.0)  # the click was the lead-in: no black fade after it
		_fade.color.a = 0.0
		var hint := find_child("SkipHint", true, false)
		if hint != null:
			hint.visible = true
		_show_subtitle()
		return
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	# Spec 23: the screen stays while the others still listen, so it goes quiet.
	_voice.stop()
	_subtitle.visible = false
	var hint := find_child("SkipHint", true, false)
	if hint != null:
		hint.visible = false
	finished.emit()


# The line for the current time, fading in after it starts and out before the next.
func _show_subtitle() -> void:
	if elapsed < 0.0 or wait_for_click:
		_subtitle.modulate.a = 0.0  # still fading in (spec 23)
		return
	var index := 0
	for i in LINE_START_SECONDS.size():
		if elapsed >= LINE_START_SECONDS[i]:
			index = i
	_subtitle.text = STORY_LINES[index]
	var start: float = LINE_START_SECONDS[index]
	var end: float = LINE_START_SECONDS[index + 1] if index + 1 < LINE_START_SECONDS.size() else _length + EXTRA_WAIT_SECONDS
	var fade_in := clampf((elapsed - start) / FADE_SECONDS, 0.0, 1.0)
	var fade_out := clampf((end - elapsed) / FADE_SECONDS, 0.0, 1.0)
	_subtitle.modulate.a = minf(fade_in, fade_out)


# ---------- building the screen (runs once) ----------

func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	theme = ui_theme

	var night := ColorRect.new()
	night.color = Title.NIGHT
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	var snow := Title.make_snow(get_viewport_rect().size.x)
	snow.amount = 90
	add_child(snow)

	var vignette := TextureRect.new()
	vignette.texture = Title.radial(Color(Title.NIGHT, 0.0), Color.BLACK, 0.35)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	_subtitle = Label.new()
	_subtitle.name = "SubtitleLabel"
	_subtitle.custom_minimum_size = Vector2(SUBTITLE_WIDTH, 0)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 38)
	_subtitle.add_theme_color_override("font_color", Title.TITLE_CREAM)
	_subtitle.add_theme_color_override("font_outline_color", Title.NIGHT)
	_subtitle.add_theme_constant_override("outline_size", 10)
	_subtitle.add_theme_color_override("font_shadow_color", Color(Title.BLOOD_RED, 0.7))
	_subtitle.add_theme_constant_override("shadow_offset_x", 2)
	_subtitle.add_theme_constant_override("shadow_offset_y", 3)
	centre.add_child(_subtitle)

	var hint := Label.new()
	hint.name = "SkipHint"
	hint.text = "Click to skip"
	hint.add_theme_color_override("font_color", Color(Title.TITLE_CREAM, 0.35))
	hint.add_theme_font_size_override("font_size", 16)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	hint.visible = not wait_for_click

	# Spec 34: browser only, before the story.
	_click_to_start = Label.new()
	_click_to_start.name = "ClickToStart"
	_click_to_start.text = "Click to start"
	_click_to_start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_click_to_start.add_theme_font_size_override("font_size", 44)
	_click_to_start.add_theme_color_override("font_color", Title.TITLE_CREAM)
	_click_to_start.add_theme_color_override("font_outline_color", Title.NIGHT)
	_click_to_start.add_theme_constant_override("outline_size", 10)
	_click_to_start.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_click_to_start.visible = wait_for_click
	centre.add_child(_click_to_start)

	# Spec 23: black on top at first, fading away during the lead-in.
	_fade = ColorRect.new()
	_fade.name = "FadeIn"
	_fade.color = Color(0, 0, 0, 1.0 if lead_in > 0.0 and not wait_for_click else 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
