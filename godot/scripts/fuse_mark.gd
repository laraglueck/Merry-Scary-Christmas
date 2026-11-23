# A fuse's own shape (spec 34), so its colour is never the only clue: red = circle,
# green = triangle, gold = diamond (Settings.FUSES). Drawn in the fuse's colour with a dark edge.
extends Control

var shape := "circle":
	set(value):
		shape = value
		queue_redraw()
var colour := Color.WHITE:
	set(value):
		colour = value
		queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	var edge := Color(0, 0, 0, 0.85)
	match shape:
		"circle":
			draw_circle(c, s * 0.5, edge)
			draw_circle(c, s * 0.5 - 2.5, colour)
		"triangle":
			_polygon([c + Vector2(0, -0.5) * s, c + Vector2(0.5, 0.42) * s, c + Vector2(-0.5, 0.42) * s], edge)
			_polygon([c + Vector2(0, -0.5 * s + 4.5), c + Vector2(0.5 * s - 4, 0.42 * s - 2.5), c + Vector2(-0.5 * s + 4, 0.42 * s - 2.5)], colour)
		"diamond":
			_polygon([c + Vector2(0, -0.5) * s, c + Vector2(0.5, 0) * s, c + Vector2(0, 0.5) * s, c + Vector2(-0.5, 0) * s], edge)
			_polygon([c + Vector2(0, -0.5 * s + 3.5), c + Vector2(0.5 * s - 3.5, 0), c + Vector2(0, 0.5 * s - 3.5), c + Vector2(-0.5 * s + 3.5, 0)], colour)


func _polygon(points: Array, fill: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), fill)
