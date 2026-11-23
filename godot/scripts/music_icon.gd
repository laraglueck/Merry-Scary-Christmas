# The music note in the music button (spec 33), drawn in code: two notes joined by a beam.
# Crossed out with a slanted line while the music is off.
extends Control

const NOTE := Color("e8d9c0")    # cream, like the other buttons' text
const STRIKE := Color("ff6b5a")  # the line through the note

var crossed := false:
	set(value):
		crossed = value
		queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2.0  # centred in the button
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var stem := maxf(1.5, s * 0.07)
	# The two note heads: slanted ovals.
	for head in [p.call(0.28, 0.78), p.call(0.72, 0.68)]:
		draw_set_transform(head, -0.4, Vector2(1.0, 0.72))
		draw_circle(Vector2.ZERO, s * 0.13, NOTE)
	draw_set_transform(Vector2.ZERO)
	# The stems, from the right edge of each head up to the beam.
	draw_line(p.call(0.39, 0.74), p.call(0.39, 0.24), NOTE, stem)
	draw_line(p.call(0.83, 0.64), p.call(0.83, 0.14), NOTE, stem)
	# The beam joining them at the top.
	draw_colored_polygon(PackedVector2Array([
		p.call(0.39 - 0.035, 0.24), p.call(0.83 + 0.035, 0.14),
		p.call(0.83 + 0.035, 0.27), p.call(0.39 - 0.035, 0.37)]), NOTE)
	if crossed:
		# A dark edge first, so the line stays visible on the cream note.
		draw_line(p.call(0.1, 0.1), p.call(0.9, 0.9), Color(0, 0, 0, 0.8), stem * 2.4)
		draw_line(p.call(0.1, 0.1), p.call(0.9, 0.9), STRIKE, stem * 1.3)
