# Placeholder maker (spec 06): creates a simple stand-in for every asset in
# asset_names.gd that has no file yet. An existing file is never overwritten,
# so real artwork is safe and the script can be run again at any time.
# Start from the repo folder:
#   godot --headless --path godot --script res://tools/make_placeholders.gd
extends SceneTree

const Names = preload("res://tools/asset_names.gd")

# One colour per asset type (the part of the file name before the first "_").
const TYPE_COLOURS := {
	"room": Color("3b2a2a"),
	"char": Color("8b1e1e"),
	"item": Color("7a5230"),
	"prop": Color("c9a227"),
	"sym": Color("1f5c3a"),
	"wire": Color("4a4a6a"),
	"ui": Color("2a2a2a"),
}
const LIT_ROOM_COLOUR := Color("b8863b")
const BORDER := 8

# About half a second of silence at 44.1 kHz.
const SILENT_FRAMES := 20


func _init() -> void:
	var made := 0
	var kept := 0
	DirAccess.make_dir_recursive_absolute(Names.IMAGE_DIR)
	DirAccess.make_dir_recursive_absolute(Names.SOUND_DIR)

	var images := Names.images()
	for file_name: String in images:
		var path: String = Names.IMAGE_DIR + file_name
		if FileAccess.file_exists(path):
			kept += 1
		elif _make_image(path, file_name, images[file_name]):
			made += 1

	for file_name: String in Names.sounds():
		var path: String = Names.SOUND_DIR + file_name
		if FileAccess.file_exists(path):
			kept += 1
		elif _make_silent_mp3(path):
			made += 1

	print("%d placeholders made, %d existing files kept" % [made, kept])
	quit()


# A flat colour with a darker border, so the edges of the image are visible.
func _make_image(path: String, file_name: String, size: Vector2i) -> bool:
	var colour := _colour_for(file_name)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(colour.darkened(0.5))
	image.fill_rect(Rect2i(BORDER, BORDER, size.x - 2 * BORDER, size.y - 2 * BORDER), colour)

	var error := image.save_webp(path) if file_name.ends_with(".webp") else image.save_png(path)
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])
		return false
	return true


func _colour_for(file_name: String) -> Color:
	if file_name.begins_with("room_") and file_name.ends_with("_lit.webp"):
		return LIT_ROOM_COLOUR
	var type := file_name.get_slice("_", 0)
	return TYPE_COLOURS.get(type, Color.MAGENTA)


# A valid MP3 that plays silence. Each frame is a 4-byte header
# (MPEG-1 Layer 3, 128 kbit/s, 44.1 kHz, stereo) followed by zeros:
# 417 bytes per frame, and all-zero audio data decodes to silence.
func _make_silent_mp3(path: String) -> bool:
	var frame := PackedByteArray()
	frame.resize(417)
	frame.fill(0)
	frame[0] = 0xFF
	frame[1] = 0xFB
	frame[2] = 0x90
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	for i in SILENT_FRAMES:
		file.store_buffer(frame)
	file.close()
	return true
