# Walking figures (spec 19). Pure functions: no network, no screens.
# game["figures"] = {player: {"x", "y", "dx", "dy"}}: where the feet stand in pixels of the room
# picture (1376 x 768) and which way the player pushes (WASD: -1..1; y up = into the room).
# The host moves everybody every frame (advance) and tells everybody.
# The feet only walk on the floor of the room (a polygon, see Settings.FLOOR_HALL). A step
# into a wall slides along it: first only the left/right part, then only the up/down part.
# First check, then change: a refused action changes nothing and returns the reason.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const MAX_STEP_SECONDS := 0.02  # a long frame is walked in small steps, so nobody jumps through a wall


# The figures at the start of a game: side by side, standing still.
# Playing alone there is only one figure (second test round).
static func new_figures(players: int = Settings.MAX_PLAYERS) -> Dictionary:
	var figures := {}
	for player in players:
		figures[player] = {"x": Settings.FIGURE_START_X[player], "y": Settings.FIGURE_START_Y, "dx": 0.0, "dy": 0.0}
	return figures


# The floor of a room as a polygon (the same everywhere until the other rooms have their own).
static func floor_polygon(_place: String) -> PackedVector2Array:
	return PackedVector2Array(Settings.FLOOR_HALL)


static func is_on_floor(place: String, feet: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(feet, floor_polygon(place))


# The highest and lowest point of the floor: far wall and front edge (for the perspective).
static func depth_range(place: String) -> Dictionary:
	var top := INF
	var bottom := -INF
	for point in floor_polygon(place):
		top = minf(top, point.y)
		bottom = maxf(bottom, point.y)
	return {"top": top, "bottom": bottom}


# The player pushes WASD: which way the figure walks until the next change. (0, 0) = stand.
static func set_direction(game: Dictionary, player: int, dx: float, dy: float) -> String:
	# 1. Check ...
	if not game.get("figures", {}).has(player):
		return "Unknown player: %d" % player
	# 2. ... then change. Never faster than full speed, diagonals included.
	var direction := Vector2(clampf(dx, -1.0, 1.0), clampf(dy, -1.0, 1.0))
	if direction.length() > 1.0:
		direction = direction.normalized()
	game["figures"][player]["dx"] = direction.x
	game["figures"][player]["dy"] = direction.y
	return ""


# Host, every frame: everybody walks on in their direction, but not into a wall.
# True if anybody moved.
static func advance(game: Dictionary, delta: float) -> bool:
	var place: String = game.get("location", "hall")
	var moved := false
	for player in game.get("figures", {}):
		var figure: Dictionary = game["figures"][player]
		if figure["dx"] == 0.0 and figure["dy"] == 0.0:
			continue
		var feet := Vector2(figure["x"], figure["y"])
		var left := delta
		while left > 0.0:
			var step := minf(left, MAX_STEP_SECONDS)
			left -= step
			var move := Vector2(figure["dx"] * Settings.WALK_SPEED, figure["dy"] * Settings.WALK_SPEED_DEPTH) * step
			feet = _step(place, feet, move)
		if feet != Vector2(figure["x"], figure["y"]):
			moved = true
		figure["x"] = feet.x
		figure["y"] = feet.y
	return moved


# One small step: straight on if the floor is there; else along the wall; else stand.
static func _step(place: String, feet: Vector2, move: Vector2) -> Vector2:
	for attempt in [move, Vector2(move.x, 0.0), Vector2(0.0, move.y)]:
		if attempt != Vector2.ZERO and is_on_floor(place, feet + attempt):
			return feet + attempt
	return feet


# How big a figure is drawn at this height of the floor: smaller far back, 1 in front.
static func depth_scale(place: String, y: float) -> float:
	var span := depth_range(place)
	var depth := clampf((y - span["top"]) / (span["bottom"] - span["top"]), 0.0, 1.0)
	return lerpf(Settings.FAR_SCALE, 1.0, depth)
