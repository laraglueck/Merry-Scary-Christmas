# Makes the two fuse box pictures from one generated picture with all three breakers UP:
#   ui_fuse_box_on.webp  - as it is: every breaker switched on
#   ui_fuse_box.webp     - the same picture with each breaker flipped upside down (off)
# Flipping keeps both pictures identical apart from the switches, so the hall can lay a
# single "on" breaker over the "off" picture (and no "DOWN" letters, which Gemini drew).
# Start from the repo folder:
#   godot --headless --path godot --script res://tools/make_fuse_box.gd -- <picture, breakers up>
extends SceneTree

const SIZE := Vector2i(1920, 1071)  # SIZE_SCREEN wide, the picture's own shape
# The three breakers (frame and rocker), in the 2000 x 1116 generated picture.
const BREAKERS := [Rect2i(815, 347, 88, 132), Rect2i(961, 347, 85, 132), Rect2i(1106, 347, 87, 132)]
const SOURCE_WIDTH := 2000.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var on := Image.load_from_file(args[0]) if args.size() == 1 else null
	if on == null:
		print("Usage: --script res://tools/make_fuse_box.gd -- <picture with all breakers up>")
		quit(1)
		return
	on.convert(Image.FORMAT_RGBA8)
	var factor := on.get_width() / SOURCE_WIDTH
	var off := on.duplicate()
	for rect in BREAKERS:
		var r := Rect2i(Vector2i(Vector2(rect.position) * factor), Vector2i(Vector2(rect.size) * factor))
		var breaker := on.get_region(r)
		breaker.flip_y()
		off.blit_rect(breaker, Rect2i(Vector2i.ZERO, r.size), r.position)
	for pair in [[on, "ui_fuse_box_on.webp"], [off, "ui_fuse_box.webp"]]:
		var image: Image = pair[0]
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		var error := image.save_webp("res://assets/images/" + pair[1], true, 0.85)
		print("%s %s" % [pair[1], "saved" if error == OK else "error %d" % error])
	quit()
