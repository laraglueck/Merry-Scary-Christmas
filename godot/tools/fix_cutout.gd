# Repairs a cut-out picture that is already see-through around the figure:
# - white background left between an arm and the body (an enclosed, almost pure white
#   area) becomes see-through;
# - the light halo along the edge (left over from removing a white background) fades out,
#   so the figure has no pale outline on a dark room.
# Overwrites the given pictures. Start from the repo folder:
#   godot --headless --path godot --script res://tools/fix_cutout.gd -- <picture.png> [...]
extends SceneTree

const PURE_WHITE := 0.94   # every channel at least this bright: background, not paint
const MIN_GAP := 60        # smaller white spots (a highlight, an eye) stay
const HALO := 0.80         # an edge pixel lighter than this fades out


func _init() -> void:
	for path in OS.get_cmdline_user_args():
		var image := Image.load_from_file(path)
		if image == null:
			print("Could not read %s" % path)
			continue
		image.convert(Image.FORMAT_RGBA8)
		var gaps := _clear_white_gaps(image)
		var halo := _soften_halo(image)
		image.save_png(path)
		print("%s: %d gap pixels cleared, %d halo pixels softened" % [path.get_file(), gaps, halo])
	quit()


func _is_white(data: PackedByteArray, i: int) -> bool:
	var at := i * 4
	var level := int(PURE_WHITE * 255)
	return data[at + 3] > 200 and data[at] >= level and data[at + 1] >= level and data[at + 2] >= level


# Finds connected white areas (flood fill) and clears those big enough to be background.
func _clear_white_gaps(image: Image) -> int:
	var w := image.get_width()
	var h := image.get_height()
	var data := image.get_data()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var cleared := 0
	for start in w * h:
		if seen[start] != 0 or not _is_white(data, start):
			continue
		var area := PackedInt32Array([start])
		seen[start] = 1
		var next := 0
		while next < area.size():
			var i := area[next]
			next += 1
			var x := i % w
			for j in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if j >= 0 and j < w * h and seen[j] == 0 and _is_white(data, j):
					seen[j] = 1
					area.append(j)
		if area.size() >= MIN_GAP:
			for i in area:
				data[i * 4 + 3] = 0
			cleared += area.size()
	image.set_data(w, h, false, Image.FORMAT_RGBA8, data)
	return cleared


# A visible pixel next to a see-through one that is very light: part of the old white
# background's edge. It fades by how light it is.
func _soften_halo(image: Image) -> int:
	var w := image.get_width()
	var h := image.get_height()
	var data := image.get_data()
	var out := data.duplicate()
	var softened := 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			var at := i * 4
			if data[at + 3] < 10:
				continue
			var edge := data[(i - 1) * 4 + 3] < 10 or data[(i + 1) * 4 + 3] < 10 \
					or data[(i - w) * 4 + 3] < 10 or data[(i + w) * 4 + 3] < 10
			if not edge:
				continue
			var light := minf(data[at], minf(data[at + 1], data[at + 2])) / 255.0
			if light > HALO:
				var keep := clampf((1.0 - light) / (1.0 - HALO), 0.0, 1.0)
				out[at + 3] = int(data[at + 3] * keep)
				softened += 1
	image.set_data(w, h, false, Image.FORMAT_RGBA8, out)
	return softened
