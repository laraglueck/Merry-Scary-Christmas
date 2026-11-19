# Room stage (spec 21): keeps a room's picture and its click areas together when the
# window is resized. The room builds everything at 1152 x 648 as before; then
# put_on_stage() moves it onto one "stage" that scales as a whole and stays centred,
# with dark bars where the window has another shape. So a click area always sits on
# its object, in a narrow window as in a wide one.
extends RefCounted

const STAGE_SIZE := Vector2(1152, 648)


# Moves all of the room's nodes onto a stage and keeps the stage fitted to the room.
static func put_on_stage(room: Control) -> Control:
	var stage := Control.new()
	stage.name = "Stage"
	stage.size = STAGE_SIZE
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in room.get_children():
		room.remove_child(child)
		stage.add_child(child)
	var bars := ColorRect.new()  # the dark bars beside or above the stage
	bars.name = "StageBars"
	bars.color = Color("0b0708")
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(bars)
	room.add_child(stage)
	room.resized.connect(fit.bind(room, stage))
	fit(room, stage)
	return stage


# The whole stage fits into the room: as large as possible, centred.
static func fit(room: Control, stage: Control) -> void:
	if room.size.x <= 0.0 or room.size.y <= 0.0:
		return
	var factor := minf(room.size.x / STAGE_SIZE.x, room.size.y / STAGE_SIZE.y)
	stage.scale = Vector2(factor, factor)
	stage.position = (room.size - STAGE_SIZE * factor) / 2.0
