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
const BACKGROUND_WHITE := 0.86  # a character's background: every colour channel at least this bright
const EDGE_SOFTNESS := 0.3      # light pixels at the edge of a cut-out fade out over this range
const PURE_WHITE := 0.97        # "pure white" like a generated picture's background
const GAP_PURE_SHARE := 0.9     # an enclosed white gap this pure counts as background
const MIN_GAP_PIXELS := 200     # smaller white spots inside a figure always stay
const DARK_HAZE := 0.12         # steam: darker than this is background
const EDGE_FADE := 0.15         # steam: fades out over this share of the width/height at each edge


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

	# Steam is white on black: the black becomes see-through.
	if file_name == "prop_steam.png":
		_black_to_transparent(image)
	# A character, item or prop on a white background (e.g. a JPG): the white around it
	# becomes see-through. White inside it (beard, snow, a clock face) stays, see _cut_out_white.
	elif _is_cut_out(file_name) and image.detect_alpha() == Image.ALPHA_NONE:
		_cut_out_white(image, file_name.begins_with("char_") or file_name.begins_with("prop_clock_hand") or file_name == "prop_doll.png")

	# A cut-out picture (see-through background) loses its empty margins first,
	# so the object itself fills the file, however much space was around it.
	# (Not the steam: it fades out softly towards its edges on purpose.)
	if image.detect_alpha() != Image.ALPHA_NONE and file_name != "prop_steam.png":
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


# Pictures that sit on top of a room or the inventory, without a background of their own.
func _is_cut_out(file_name: String) -> bool:
	for start in ["char_", "item_", "prop_", "egg_"]:
		if file_name.begins_with(start):
			return true
	return false


# The darker a pixel, the more see-through it gets; what stays is white.
# Near-black haze disappears completely, and everything fades out towards the
# picture's edges, so no straight border shows over the room.
# Only right for something light (steam, smoke) on a black background.
func _black_to_transparent(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	for y in height:
		for x in width:
			var colour := image.get_pixel(x, y)
			var brightness := maxf(colour.r, maxf(colour.g, colour.b))
			var alpha := clampf((brightness - DARK_HAZE) / (1.0 - DARK_HAZE), 0.0, 1.0)
			var edge := minf(minf(x, width - 1 - x) / (width * EDGE_FADE), minf(y, height - 1 - y) / (height * EDGE_FADE))
			image.set_pixel(x, y, Color(1, 1, 1, alpha * clampf(edge, 0.0, 1.0)))


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


# Makes the white background around a character see-through:
# - all white connected to the picture's border (flood fill);
# - only for characters (`with_gaps`): white gaps enclosed by the figure (between an
#   arm and the body) when they are almost all pure white like the background. White parts of the character itself
#   (a beard, a snowman's shaded body) are hardly ever pure white, so they stay.
# Light pixels right at the edge of the character fade out, so the outline stays
# smooth instead of jagged.
func _cut_out_white(image: Image, with_gaps: bool) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var data := image.get_data()
	var seen := PackedByteArray()  # 1 = looked at, 2 = background (see-through)
	seen.resize(width * height)

	var border := PackedInt32Array()
	for x in width:
		border.append(x)
		border.append((height - 1) * width + x)
	for y in height:
		border.append(y * width)
		border.append(y * width + width - 1)
	for index in _white_area(data, width, height, border, seen):
		seen[index] = 2

	for start in width * height:
		if not with_gaps:
			break
		if seen[start] != 0 or not _is_light(data, start):
			continue
		var gap := _white_area(data, width, height, PackedInt32Array([start]), seen)
		var pure := 0
		for index in gap:
			if _is_light(data, index, PURE_WHITE):
				pure += 1
		if gap.size() >= MIN_GAP_PIXELS and pure >= gap.size() * GAP_PURE_SHARE:
			for index in gap:
				seen[index] = 2

	for index in width * height:
		if seen[index] == 2:
			data[index * 4 + 3] = 0
			continue
		# Soft edge: a pixel next to the removed background fades by how light it is.
		var x := index % width
		var touches := (x > 0 and seen[index - 1] == 2) or (x < width - 1 and seen[index + 1] == 2) \
				or (index >= width and seen[index - width] == 2) \
				or (index < (height - 1) * width and seen[index + width] == 2)
		if not touches:
			continue
		var at := index * 4
		var darkest := mini(data[at], mini(data[at + 1], data[at + 2])) / 255.0
		var alpha := clampf((1.0 - darkest) / EDGE_SOFTNESS, 0.0, 1.0)
		data[at + 3] = int(alpha * 255)
	image.set_data(width, height, false, Image.FORMAT_RGBA8, data)


# Every channel of this pixel at least `limit` bright.
func _is_light(data: PackedByteArray, index: int, limit := BACKGROUND_WHITE) -> bool:
	var at := index * 4
	var level := int(limit * 255)
	return data[at] >= level and data[at + 1] >= level and data[at + 2] >= level


# All light pixels connected to the start pixels (flood fill); marks them as seen.
func _white_area(data: PackedByteArray, width: int, height: int, starts: PackedInt32Array, seen: PackedByteArray) -> PackedInt32Array:
	var area := PackedInt32Array()
	var queue := starts.duplicate()
	var next := 0
	while next < queue.size():
		var index := queue[next]
		next += 1
		if seen[index] != 0 or not _is_light(data, index):
			continue
		seen[index] = 1
		area.append(index)
		var x := index % width
		if x > 0:
			queue.append(index - 1)
		if x < width - 1:
			queue.append(index + 1)
		if index >= width:
			queue.append(index - width)
		if index < (height - 1) * width:
			queue.append(index + width)
	return area
