# Makes the view out of the living room window (spec 26): a part of the front garden
# (room_garden.webp) with the full moon (prop_moon_full.png) in the sky, BEHIND the trees,
# the lamp post and the falling snow: the moon only shows where the picture is sky.
# Saves two pictures: assets/images/view_window_garden.png (clear night, bright moon) and
# view_window_garden_cloudy.png (the moon pale behind clouds). Start from the repo folder:
#   godot --headless --path godot --script res://tools/make_window_view.gd
extends SceneTree

const IMAGES := "res://assets/images/"
const REGION := Rect2i(0, 150, 620, 457)  # trees, fence, gate post and lamp, no house
const MOON_CENTRE := Vector2i(490, 48)    # in the region: open sky between the lamp and the house
const MOON_SIZE := 76
const HALO := 1.7                          # a faint glow around the moon, this many radii wide
const CLOUDY_MOON := 0.25                  # behind clouds only a pale moon shows through


func _init() -> void:
	var garden := Image.load_from_file(ProjectSettings.globalize_path(IMAGES + "room_garden.webp"))
	garden.convert(Image.FORMAT_RGBA8)
	var moon := Image.load_from_file(ProjectSettings.globalize_path(IMAGES + "prop_moon_full.png"))
	moon.convert(Image.FORMAT_RGBA8)
	moon.resize(MOON_SIZE, MOON_SIZE, Image.INTERPOLATE_LANCZOS)
	_save(_paint(garden.get_region(REGION), moon, 1.0), "view_window_garden.png")
	_save(_paint(garden.get_region(REGION), moon, CLOUDY_MOON), "view_window_garden_cloudy.png")
	quit()


func _save(view: Image, file_name: String) -> void:
	view.save_png(ProjectSettings.globalize_path(IMAGES + file_name))
	print("saved ", file_name)


# The moon (and its glow) painted into the sky with this strength (1 = bright).
func _paint(view: Image, moon: Image, strength: float) -> Image:
	var radius := MOON_SIZE / 2.0
	var reach := int(radius * HALO)
	for y in range(-reach, reach + 1):
		for x in range(-reach, reach + 1):
			var at := MOON_CENTRE + Vector2i(x, y)
			if at.x < 0 or at.y < 0 or at.x >= view.get_width() or at.y >= view.get_height():
				continue
			var sky_pixel := view.get_pixel(at.x, at.y)
			var sky := _skyness(sky_pixel)
			if sky <= 0.0:
				continue  # a branch, the lamp, a snowflake: in front of the moon
			var colour := sky_pixel
			var distance := Vector2(x, y).length()
			if distance < reach:  # the glow
				var glow := 0.18 * strength * pow(1.0 - distance / reach, 2.0) * sky
				colour = colour.lerp(Color(0.9, 0.93, 1.0), glow)
			var mx := x + int(radius)
			var my := y + int(radius)
			if mx >= 0 and my >= 0 and mx < MOON_SIZE and my < MOON_SIZE:
				var m := moon.get_pixel(mx, my)
				colour = colour.lerp(Color(m.r, m.g, m.b), m.a * sky * strength)
			colour.a = 1.0
			view.set_pixel(at.x, at.y, colour)
	return view


# 1 for the night sky, 0 for everything in front of it, soft in between so the edges stay
# smooth. The sky is blue (blue clearly above red) and mid-bright: the brown lamp and the
# white snowflakes are not blue enough, the thin dark-blue branches are too dark.
func _skyness(pixel: Color) -> float:
	var blue := clampf(((pixel.b - pixel.r) * 255.0 - 18.0) / 14.0, 0.0, 1.0)
	var brightness := (0.3 * pixel.r + 0.59 * pixel.g + 0.11 * pixel.b) * 255.0
	var not_dark := clampf((brightness - 55.0) / 12.0, 0.0, 1.0)
	return blue * not_dark
