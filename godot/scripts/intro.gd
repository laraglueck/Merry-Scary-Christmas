# The loading screen (spec 12): a dark night with falling snow, the story read out
# (voice_title.mp3) and shown as subtitles, one line after the other. When the voice
# ends, or on a click or key, it sends `finished` and main.gd shows the title.
# The music is played by main.gd, so it keeps going into the title without a break.
extends Control

signal finished

const Title = preload("res://scripts/title.gd")

const SOUNDS := "res://assets/sounds/"

# The story, exactly as the voice reads it, one subtitle per entry.
const STORY_LINES := [
	"I was Santa's most loyal helper.",
	"I had one job: deliver the presents on Christmas Eve.",
	"Then the storm came. I was stuck in the snow, and nothing got delivered.",
	"The children woke up to empty stockings, and I was fired.",
	"Now I live alone in this old house, and I hate Christmas.",
	"Every Christmas Eve, I take my revenge.",
	"Three presents, stolen and hidden somewhere in these walls.",
	"Think you can find them before the time runs out?",
]
# Moves single lines earlier (minus) or later (plus), in seconds, if the automatic
# timing doesn't match the voice. One number per line; leave 0.0 where it fits.
const LINE_SHIFT_SECONDS := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

const LEAD_IN_SECONDS := 0.4      # silence before the voice starts speaking
const PAUSE_LETTERS := 14         # the pause after a line counts like this many letters
const FADE_SECONDS := 0.35        # a subtitle fades in and out this fast
const EXTRA_WAIT_SECONDS := 1.5   # without sound, go on this long after the voice's length
const SUBTITLE_WIDTH := 1060.0    # fixed width, so the label can wrap (see TEAM-GUIDE pitfalls)

var net: Node = null  # main.gd hands this in like for every screen; the intro doesn't need it
var elapsed := 0.0

var _voice: AudioStreamPlayer
var _subtitle: Label
var _times: Array = []
var _length := 0.0
var _done := false


# When each line starts (seconds), shared out by the number of letters of each line:
# a long line is read longer. `total` is the voice's length.
static func line_times(lines: Array, total: float) -> Array:
	var weights := []
	var sum := 0.0
	for line: String in lines:
		weights.append(float(line.length() + PAUSE_LETTERS))
		sum += weights[-1]
	var usable := total - LEAD_IN_SECONDS
	var times := []
	var start := LEAD_IN_SECONDS
	for i in lines.size():
		var shift: float = LINE_SHIFT_SECONDS[i] if i < LINE_SHIFT_SECONDS.size() else 0.0
		times.append(start + shift)
		start += usable * weights[i] / sum
	return times


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
	_voice.autoplay = DisplayServer.get_name() != "headless"
	_voice.finished.connect(_finish)
	add_child(_voice)
	_length = stream.get_length()
	_times = line_times(STORY_LINES, _length)
	_show_subtitle()


func _process(delta: float) -> void:
	advance(delta)


# Moves the story clock on (the tests call this to fast-forward).
func advance(seconds: float) -> void:
	if _done:
		return
	elapsed += seconds
	_show_subtitle()
	if elapsed > _length + EXTRA_WAIT_SECONDS:
		_finish()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


# The line for the current time, fading in after it starts and out before the next.
func _show_subtitle() -> void:
	var index := 0
	for i in _times.size():
		if elapsed >= _times[i]:
			index = i
	_subtitle.text = STORY_LINES[index]
	var start: float = _times[index]
	var end: float = _times[index + 1] if index + 1 < _times.size() else _length + EXTRA_WAIT_SECONDS
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
