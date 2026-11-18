# Draws the floor plan onto the empty framed paper and saves it as ui_house_plan.webp.
# Image generators cannot draw an exact layout, so the plan is drawn here, matching the
# hall picture: one hallway from the front door, living room front left, bathroom back
# left, a small bedroom on the right, the stairs at the back on the right, the fuse box
# next to the front door, and an empty legend box. Lines look hand-drawn (a wobbly pen,
# corners that run past each other) and the rooms look like faded watercolour.
# The rooms sit exactly where hall.gd puts its tiles (PLAN_ROOMS, LEGEND_BOX), so the
# hall needs no change.
# The paper is house_plan_paper.webp next to this script: the old Gemini plan picture with
# its drawing removed. Start from the repo folder:
#   godot --headless --path godot --script res://tools/draw_house_plan.gd [-- <paper> [<save as>]]
extends SceneTree

const PAPER := "res://tools/house_plan_paper.webp"
const OUT := "res://assets/images/ui_house_plan.webp"
const SIZE := Vector2i(1376, 768)  # the size hall.gd measures the plan in (PICTURE_SIZE)
const SEED := 2026                 # same seed, same wobbles: the plan looks the same every time

# Rooms by fuse (same rects as hall.gd PLAN_ROOMS): living room, bathroom, bedroom.
const LIVING := Rect2i(349, 317, 266, 231)
const BATHROOM := Rect2i(424, 140, 190, 164)
const BEDROOM := Rect2i(765, 262, 236, 205)
const LEGEND := Rect2i(892, 530, 298, 111)  # hall.gd LEGEND_BOX: the inside of the box

# Where the walls are.
const LEFT := 349          # living room left
const BATH_LEFT := 424     # bathroom left (narrower than the living room)
const HALL_LEFT := 615     # the hallway runs between the rooms on the left ...
const HALL_RIGHT := 765    # ... and the bedroom on the right
const RIGHT := 1001        # bedroom right
const BACK := 140          # back wall of the house
const MIDDLE := 310        # wall between bathroom and living room
const BED_BACK := 262      # bedroom back wall
const BED_FRONT := 467     # bedroom front wall
const FRONT := 548         # front wall with the front door
const FRONT_DOOR := Vector2i(652, 720)   # x from, x to
const LIVING_DOOR := Vector2i(470, 520)  # y from, y to, in the hallway's left wall
const BATH_DOOR := Vector2i(205, 255)
const BED_DOOR := Vector2i(390, 440)     # in the hallway's right wall, opposite the living room

const INK := Color("2e2118")
const WALL_WIDTH := 5.0
const ROOM_TINTS := [Color("9b3f3f"), Color("4f7f5c"), Color("b8902f")]
const TINT_STRENGTH := 0.5

var image: Image
var rng := RandomNumberGenerator.new()
var wobble := FastNoiseLite.new()  # slow side-to-side movement of the pen
var wash := FastNoiseLite.new()    # uneven watercolour


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var paper: String = args[0] if args.size() >= 1 else PAPER
	var out: String = args[1] if args.size() >= 2 else OUT
	image = Image.load_from_file(paper)
	if image == null:
		print("Could not read the paper: %s" % paper)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	rng.seed = SEED
	wobble.seed = SEED
	wobble.frequency = 0.012
	wash.seed = SEED + 1
	wash.frequency = 0.02

	# Living room and bathroom reach the wall between them (the hall's tiles stop a bit short).
	_wash(Rect2i(LEFT, MIDDLE, HALL_LEFT - LEFT, FRONT - MIDDLE), ROOM_TINTS[0])
	_wash(Rect2i(BATH_LEFT, BACK, HALL_LEFT - BATH_LEFT, MIDDLE - BACK), ROOM_TINTS[1])
	_wash(Rect2i(HALL_RIGHT, BED_BACK, RIGHT - HALL_RIGHT, BED_FRONT - BED_BACK), ROOM_TINTS[2])
	_walls()
	_doors()
	_stairs()
	_fuse_box()
	_legend_box()

	var error := image.save_webp(out, true, 0.85)
	print("%s saved" % out.get_file() if error == OK else "Could not save (error %d)" % error)
	quit(0 if error == OK else 1)


# ---------- the plan ----------

# The outline is not a rectangle: the bathroom is narrower than the living room, and the
# bedroom sticks out on the right with no room behind or in front of it. A wall that ends
# at a door opening does not run past that end (false).
func _walls() -> void:
	# Outer walls, going round the house.
	_wall(Vector2(LEFT, FRONT), Vector2(FRONT_DOOR.x, FRONT), true, false)
	_wall(Vector2(FRONT_DOOR.y, FRONT), Vector2(HALL_RIGHT, FRONT), false, true)
	_wall(Vector2(HALL_RIGHT, FRONT), Vector2(HALL_RIGHT, BED_FRONT))
	_wall(Vector2(HALL_RIGHT, BED_FRONT), Vector2(RIGHT, BED_FRONT))
	_wall(Vector2(RIGHT, BED_FRONT), Vector2(RIGHT, BED_BACK))
	_wall(Vector2(RIGHT, BED_BACK), Vector2(HALL_RIGHT, BED_BACK))
	_wall(Vector2(HALL_RIGHT, BED_BACK), Vector2(HALL_RIGHT, BACK))
	_wall(Vector2(HALL_RIGHT, BACK), Vector2(BATH_LEFT, BACK))
	_wall(Vector2(BATH_LEFT, BACK), Vector2(BATH_LEFT, MIDDLE))
	_wall(Vector2(BATH_LEFT, MIDDLE), Vector2(LEFT, MIDDLE))
	_wall(Vector2(LEFT, MIDDLE), Vector2(LEFT, FRONT))
	# Inside walls, with the door openings left out.
	_wall(Vector2(BATH_LEFT, MIDDLE), Vector2(HALL_LEFT, MIDDLE))
	_wall(Vector2(HALL_LEFT, BACK), Vector2(HALL_LEFT, BATH_DOOR.x), true, false)
	_wall(Vector2(HALL_LEFT, BATH_DOOR.y), Vector2(HALL_LEFT, LIVING_DOOR.x), false, false)
	_wall(Vector2(HALL_LEFT, LIVING_DOOR.y), Vector2(HALL_LEFT, FRONT), false, true)
	_wall(Vector2(HALL_RIGHT, BED_BACK), Vector2(HALL_RIGHT, BED_DOOR.x), true, false)
	_wall(Vector2(HALL_RIGHT, BED_DOOR.y), Vector2(HALL_RIGHT, BED_FRONT), false, true)


# Each door: a thin line for the open door leaf and a quarter circle for its swing.
# The leaf points straight into the room; the arc runs from its tip back to the wall.
func _doors() -> void:
	_door(Vector2(HALL_LEFT, BATH_DOOR.x), BATH_DOOR.y - BATH_DOOR.x, Vector2.LEFT)
	_door(Vector2(HALL_LEFT, LIVING_DOOR.x), LIVING_DOOR.y - LIVING_DOOR.x, Vector2.LEFT)
	_door(Vector2(HALL_RIGHT, BED_DOOR.x), BED_DOOR.y - BED_DOOR.x, Vector2.RIGHT)
	_door(Vector2(FRONT_DOOR.x, FRONT), FRONT_DOOR.y - FRONT_DOOR.x, Vector2.UP)


func _door(hinge: Vector2, width: float, into: Vector2) -> void:
	_stroke(hinge, hinge + into * width, 2.2, 0.0, 0.0)
	# The swing: from the open leaf round to where the door closes along the wall.
	var closed := Vector2.DOWN if into.y == 0 else Vector2.RIGHT
	var from_angle := into.angle()
	var to_angle := from_angle + into.angle_to(closed)
	_arc(hinge, width, from_angle, to_angle)


# The stairs: a tall narrow flight against the hallway's right wall at the back,
# climbing towards the back wall: a tall rectangle full of steps.
func _stairs() -> void:
	var left := HALL_RIGHT - 62.0
	var top := BACK + 3.0
	var bottom := top + 150.0
	_stroke(Vector2(left, top), Vector2(left, bottom), 2.6, 2.0, 3.0)
	_stroke(Vector2(left, bottom), Vector2(HALL_RIGHT, bottom), 2.6, 3.0, 0.0)
	var y := bottom - 13.0
	while y > top + 6:
		var tilt := rng.randf_range(-1.2, 1.2)
		_stroke(Vector2(left + 1, y + tilt), Vector2(HALL_RIGHT - 3, y - tilt), 1.8, 0.0, 0.0)
		y -= 13.0


# A small empty square on the hallway wall next to the front door.
func _fuse_box() -> void:
	_box(Rect2(HALL_LEFT + 8, FRONT - 54, 20, 20), 2.2)


# An empty box with a double border; hall.gd writes the legend into it.
func _legend_box() -> void:
	_box(Rect2(LEGEND.grow(10)), 2.6)
	_box(Rect2(LEGEND.grow(4)), 1.8)


# ---------- the pen ----------

# A wall: one firm stroke and a faint second one beside it, like a pen gone over twice.
func _wall(from: Vector2, to: Vector2, run_past_start := true, run_past_end := true) -> void:
	var before := rng.randf_range(3.0, 9.0) if run_past_start else -WALL_WIDTH / 2
	var after := rng.randf_range(3.0, 9.0) if run_past_end else -WALL_WIDTH / 2
	_stroke(from, to, WALL_WIDTH, before, after)
	var side := (to - from).normalized().orthogonal() * rng.randf_range(1.5, 2.5)
	_stroke(from + side, to + side, 1.6, before - 2, after - 2, 0.45)


func _box(rect: Rect2, width: float) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_stroke(corners[i], corners[(i + 1) % 4], width, rng.randf_range(1.0, 4.0), rng.randf_range(1.0, 4.0))


# A pen line from `from` to `to` that runs `before` / `after` pixels past its ends,
# moves a little from side to side and is not equally thick everywhere.
func _stroke(from: Vector2, to: Vector2, width: float, before: float, after: float, strength := 0.92) -> void:
	var direction := (to - from).normalized()
	var start := from - direction * before
	var end := to + direction * after
	var length := start.distance_to(end)
	var side := direction.orthogonal()
	var offset := rng.randf_range(0.0, 1000.0)
	var steps := int(length) + 1
	for i in steps + 1:
		var t := float(i) / steps
		var along := offset + t * length
		var point := start.lerp(end, t) + side * wobble.get_noise_1d(along) * 2.2
		var thickness := width * (0.8 + 0.35 * (wobble.get_noise_1d(along * 3.0 + 500.0) + 1.0) / 2.0)
		_dab(point, thickness / 2.0, strength)


func _arc(centre: Vector2, radius: float, from_angle: float, to_angle: float) -> void:
	var steps := int(radius * absf(to_angle - from_angle)) + 1
	var offset := rng.randf_range(0.0, 1000.0)
	for i in steps + 1:
		var angle := lerpf(from_angle, to_angle, float(i) / steps)
		var r := radius + wobble.get_noise_1d(offset + i) * 1.5
		_dab(centre + Vector2(cos(angle), sin(angle)) * r, 0.9, 0.85)


# One round touch of ink with a soft edge, mixed into the paper.
func _dab(centre: Vector2, radius: float, strength: float) -> void:
	var reach := int(ceil(radius + 1))
	for y in range(int(centre.y) - reach, int(centre.y) + reach + 1):
		for x in range(int(centre.x) - reach, int(centre.x) + reach + 1):
			if x < 0 or y < 0 or x >= SIZE.x or y >= SIZE.y:
				continue
			var cover := clampf(radius + 0.5 - Vector2(x, y).distance_to(centre), 0.0, 1.0) * strength
			if cover > 0.0:
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(INK, cover))


# A room's faded watercolour: uneven inside, a little darker where the paint pooled at
# the edges, painted into the paper so stains and creases still show.
func _wash(room: Rect2i, tint: Color) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var edge := mini(mini(x - room.position.x, room.end.x - 1 - x), mini(y - room.position.y, room.end.y - 1 - y))
			var strength := TINT_STRENGTH * (0.8 + 0.3 * wash.get_noise_2d(x, y))
			if edge < 6:
				strength *= 1.0 + 0.25 * (6 - edge) / 6.0
			var paper := image.get_pixel(x, y)
			image.set_pixel(x, y, paper.lerp(paper * tint, clampf(strength, 0.0, 1.0)))
