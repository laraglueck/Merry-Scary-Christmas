# Tears item_photo.png into three pieces (spec 21): item_photo_piece_1/2/3.png.
# Each piece keeps the photo's full size, see-through outside its strip, so the three
# laid on top of each other give the whole photo again (the puzzle shows that).
# The tears are jagged, with light paper fibres along them. The same seed gives the
# same tears. Start from the repo folder:
#   godot --headless --path godot --script res://tools/cut_photo.gd
extends SceneTree

const SOURCE := "res://assets/images/item_photo.png"
const OUT := "res://assets/images/item_photo_piece_%d.png"
const PIECES := 3
const SEED := 1990           # the year on the back of the photo, so to say
const JAG := 9.0             # how far a tear wanders left and right, in pixels
const FIBRE := 3             # width of the light paper edge along a tear
const FIBRE_COLOUR := Color("f3ead6")


func _init() -> void:
	var photo := Image.load_from_file(SOURCE)
	if photo == null:
		print("Could not read %s" % SOURCE)
		quit(1)
		return
	photo.convert(Image.FORMAT_RGBA8)
	var width := photo.get_width()
	var height := photo.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# The tears: for each row, where the cut between piece i and i + 1 is.
	var tears := []
	for i in range(1, PIECES):
		var base := width * float(i) / PIECES
		var line := PackedFloat32Array()
		var x := base
		for y in height:
			x += rng.randf_range(-2.5, 2.5)          # a random walk ...
			x = clampf(x, base - JAG, base + JAG)    # ... that stays near its place
			line.append(x)
		tears.append(line)

	for piece in PIECES:
		var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		for y in height:
			var left: float = 0.0 if piece == 0 else tears[piece - 1][y]
			var right: float = float(width) if piece == PIECES - 1 else tears[piece][y]
			for x in width:
				if x < left or x >= right:
					continue
				var colour := photo.get_pixel(x, y)
				var to_tear := minf(x - left if piece > 0 else 999.0, right - x if piece < PIECES - 1 else 999.0)
				if to_tear < FIBRE and colour.a > 0.5:
					colour = colour.lerp(FIBRE_COLOUR, 0.8)
				image.set_pixel(x, y, colour)
		var path := OUT % (piece + 1)
		var error := image.save_png(path)
		print("%s %s" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	quit()
