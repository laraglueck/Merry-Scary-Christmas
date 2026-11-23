# Tests for spec 34: clickable things glow on hover.
extends "res://tests/base_test.gd"

const HoverGlow = preload("res://scripts/hover_glow.gd")

# Every room and the click areas (Buttons over the picture) that must glow.
const ROOMS := {
	"res://scenes/hall.tscn": ["FuseBoxButton", "Door_living_room", "StoryWreath", "Door_bathroom",
			"StairsButton", "Door_bedroom", "HousePlanButton"],
	"res://scenes/living_room.tscn": ["ClockButton", "NoteButton", "DoorHall", "WindowButton"],
	"res://scenes/bathroom.tscn": ["Spot_bathtub", "Spot_cold_tap", "Spot_hot_tap", "Spot_mirror", "Spot_door_hall"],
	"res://scenes/bedroom.tscn": ["CalendarHotspot", "ChestHotspot", "DoorHall"],
	"res://scenes/attic.tscn": [],
}
# The things to pick up (TextureButtons) in each room.
const ITEMS := {
	"res://scenes/hall.tscn": ["DollNote"],
	"res://scenes/living_room.tscn": ["GiftButton", "PhotoPiece", "Cookies"],
	"res://scenes/bathroom.tscn": ["Gift", "PhotoPiece"],
	"res://scenes/bedroom.tscn": [],
	"res://scenes/attic.tscn": ["Key"],
}


func _is_glow(style) -> bool:
	return style is StyleBoxFlat and style.shadow_size >= 8 and style.shadow_color.a > 0.2 \
			and style.bg_color.a > 0.0 and style.bg_color.a < 0.3


func test_the_glow_is_soft_and_warm() -> void:
	var style := HoverGlow.glow_style()
	assert_true(_is_glow(style), "a halo, a faint fill")
	assert_true(style.shadow_color.r > style.shadow_color.b, "warm (gold), not blue")


func test_a_click_area_glows_only_on_hover() -> void:
	var button := Button.new()
	HoverGlow.spot(button)
	assert_true(button.get_theme_stylebox("normal") is StyleBoxEmpty, "nothing to see without the mouse")
	assert_true(_is_glow(button.get_theme_stylebox("hover")), "glows on hover")
	assert_eq(button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "the hand")
	button.free()


func test_a_thing_to_pick_up_lights_up_and_goes_back() -> void:
	var item := TextureButton.new()
	item.modulate = Color(0.5, 0.5, 0.5)  # dimmed, like the doll's note
	HoverGlow.item(item)
	tree.root.add_child(item)
	var halo: Control = item.find_child("HoverGlow", false, false)
	assert_true(halo != null and not halo.visible, "a halo, hidden at first")
	item.mouse_entered.emit()
	assert_true(item.modulate.v > 0.5, "lights up: %s" % item.modulate)
	assert_true(halo != null and halo.visible, "the halo shows")
	item.mouse_exited.emit()
	assert_eq(item.modulate, Color(0.5, 0.5, 0.5), "back as it was")
	assert_true(halo != null and not halo.visible, "the halo goes")
	item.queue_free()


func test_every_room_uses_the_glow() -> void:
	for path in ROOMS:
		var room: Node = load(path).instantiate()
		if "seed_value" in room:
			room.seed_value = 42
		tree.root.add_child(room)
		for node_name in ROOMS[path]:
			var button: Control = room.find_child(node_name, true, false)
			assert_true(button != null, "%s in %s" % [node_name, path.get_file()])
			if button != null:
				assert_true(_is_glow(button.get_theme_stylebox("hover")), "%s glows in %s" % [node_name, path.get_file()])
		for node_name in ITEMS[path]:
			var item: Control = room.find_child(node_name, true, false)
			assert_true(item != null and item.find_child("HoverGlow", false, false) != null,
					"%s lights up in %s" % [node_name, path.get_file()])
		room.queue_free()
		await wait_frames(1)
