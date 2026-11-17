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

	# Shrink to fit inside the listed size; a smaller picture stays as it is.
	var target: Vector2i = images[file_name]
	var factor := minf(float(target.x) / image.get_width(), float(target.y) / image.get_height())
	if factor < 1.0:
		image.resize(roundi(image.get_width() * factor), roundi(image.get_height() * factor), Image.INTERPOLATE_LANCZOS)

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
