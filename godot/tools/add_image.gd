# Puts one finished picture into the game under its asset name.
# It loads the source picture (JPG, PNG or WebP), makes it smaller if it is larger
# than the size listed in asset_names.gd (never larger, proportions stay), and
# saves it as PNG or WebP according to the asset name. It replaces the placeholder.
# Start from the repo folder:
#   godot --headless --path godot --script res://tools/add_image.gd -- <picture> <asset name>
# Example:
#   ... --script res://tools/add_image.gd -- ~/Downloads/hall.jpg room_hall.webp
extends SceneTree

const Names = preload("res://tools/asset_names.gd")

const WEBP_QUALITY := 0.85
const MAX_KILOBYTES := 500
const VISIBLE_ALPHA := 0.5  # a pixel more solid than this counts as part of the object


func _init() -> void:
	quit(_run(OS.get_cmdline_user_args()))


# Returns 0 if the picture was added, 1 if something was wrong.
func _run(args: PackedStringArray) -> int:
	if args.size() != 2:
		print("Usage: --script res://tools/add_image.gd -- <picture> <asset name>")
		return 1
	var source := args[0]
	var file_name := args[1]

	var images := Names.images()
	if not images.has(file_name):
		print("Unknown asset name: %s. Add it to asset_names.gd first." % file_name)
		return 1

	var image := Image.load_from_file(source)
	if image == null:
		print("Could not read the picture: %s" % source)
		return 1

	# A cut-out picture (see-through background) loses its empty margins first,
	# so the object itself fills the file, however much space was around it.
	if image.detect_alpha() != Image.ALPHA_NONE:
		var used := _solid_rect(image)
		if used.size.x > 0 and used.size.y > 0:
			image = image.get_region(used)

	# Shrink to fit inside the listed size; a smaller picture stays as it is.
	var target: Vector2i = images[file_name]
	var factor := minf(float(target.x) / image.get_width(), float(target.y) / image.get_height())
	if factor < 1.0:
		image.resize(roundi(image.get_width() * factor), roundi(image.get_height() * factor), Image.INTERPOLATE_LANCZOS)

	# Symbols are a dark shape on white: the white becomes see-through.
	if file_name.begins_with("sym_"):
		_white_to_transparent(image)

	var path: String = Names.IMAGE_DIR + file_name
	var error: Error
	if file_name.ends_with(".webp"):
		error = image.save_webp(path, true, WEBP_QUALITY)
	else:
		error = image.save_png(path)
	if error != OK:
		print("Could not save %s (error %d)" % [path, error])
		return 1

	var kilobytes := FileAccess.get_file_as_bytes(path).size() / 1024.0
	print("%s saved: %d x %d, %.0f KB" % [file_name, image.get_width(), image.get_height(), kilobytes])
	if kilobytes > MAX_KILOBYTES:
		print("WARNING: larger than %d KB, the limit for one image." % MAX_KILOBYTES)
	return 0


# The smallest rectangle that holds every clearly visible pixel. Faint specks
# that a background remover left behind (almost see-through) are ignored.
func _solid_rect(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > VISIBLE_ALPHA:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < 0:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


# The brighter a pixel, the more see-through it gets: pure white disappears,
# the dark shape stays solid, and the soft edge between them stays smooth.
# Only right for a dark shape on a white background.
func _white_to_transparent(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			var brightness := minf(colour.r, minf(colour.g, colour.b))
			colour.a = 1.0 - brightness
			image.set_pixel(x, y, colour)
