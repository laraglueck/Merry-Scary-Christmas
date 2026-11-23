# Tests for spec 28: five Easter-egg pictures behind the advent calendar doors.
extends "res://tests/base_test.gd"

const BedroomScene = preload("res://scenes/bedroom.tscn")
const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")
const BedroomScript = preload("res://scripts/bedroom.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")


func new_game(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return GameRules.new_game(rng)


func test_egg_doors_are_five_free_doors_and_stable() -> void:
	var seen := {}
	for seed_value in range(30):
		var game := new_game(seed_value)
		var room: Dictionary = game["bedroom"]
		var clue: Dictionary = game["living_room"]
		var doors := BedroomRules.egg_doors(room, clue)
		assert_eq(doors.size(), 5, "five eggs (seed %d)" % seed_value)
		var taken := [int(clue["hour"]), int(clue["minute"]), BedroomRules.photo_door(room, clue)]
		for door in doors:
			assert_true(door in range(1, 13), "a real door")
			assert_true(door not in taken, "not a clock door, not the photo door (seed %d)" % seed_value)
		var unique := {}
		for door in doors:
			unique[door] = true
		assert_eq(unique.size(), doors.size(), "all different doors")
		assert_eq(BedroomRules.egg_doors(room.duplicate(true), clue.duplicate(true)), doors, "same after save/resume")
		seen[str(doors)] = true
	assert_true(seen.size() > 5, "different games hide them behind different doors")


func open_bedroom(seed_value := 42) -> Node:
	var bedroom = BedroomScene.instantiate()
	bedroom.seed_value = seed_value
	tree.root.add_child(bedroom)
	return bedroom


func solve_chest(bedroom: Node) -> void:
	var room: Dictionary = bedroom.offline_game["bedroom"]
	GameRules.apply(bedroom.offline_game, 0, "set_wheels", {"symbols": room["wheels"]})
	bedroom._update_room()


func egg_doors_of(bedroom: Node) -> Array[int]:
	var game: Dictionary = bedroom.offline_game
	return BedroomRules.egg_doors(game["bedroom"], game["living_room"])


func test_egg_doors_are_locked_before_the_chest() -> void:
	BedroomScript.forget_eggs()
	var bedroom := open_bedroom()
	press(bedroom, "CalendarHotspot")
	for door in egg_doors_of(bedroom):
		assert_true(bedroom.calendar_doors[door - 1].disabled, "door %d is stuck" % door)


func test_an_egg_door_shows_its_picture_inside_the_door() -> void:
	BedroomScript.forget_eggs()
	var bedroom := open_bedroom()
	solve_chest(bedroom)
	press(bedroom, "CalendarHotspot")
	var doors := egg_doors_of(bedroom)
	for i in doors.size():
		var button: Button = bedroom.calendar_doors[doors[i] - 1]
		button.pressed.emit()
		assert_eq(button.icon, bedroom.EGG_ART[i], "door %d shows egg %d" % [doors[i], i + 1])
		assert_true(button.get_theme_constant("icon_max_width") >= 80, "the picture is big enough to see")
		assert_eq(bedroom.status_label.text, "", "no text")
	var empty := 0
	for door in range(1, 13):
		if door not in doors and door != BedroomRules.photo_door(bedroom.offline_game["bedroom"], bedroom.offline_game["living_room"]) \
				and door != int(bedroom.offline_game["living_room"]["hour"]) and door != int(bedroom.offline_game["living_room"]["minute"]):
			empty = door
			break
	bedroom.calendar_doors[empty - 1].pressed.emit()
	assert_contains(bedroom.status_label.text, "Door %d is empty" % empty, "the other doors stay empty")


func test_every_egg_screams_the_first_time() -> void:
	BedroomScript.forget_eggs()
	var bedroom := open_bedroom()
	solve_chest(bedroom)
	press(bedroom, "CalendarHotspot")
	var doors := egg_doors_of(bedroom)
	for i in doors.size():
		bedroom.room_sound.stream = null
		bedroom.calendar_doors[doors[i] - 1].pressed.emit()
		assert_eq(bedroom.room_sound.stream, bedroom.SCARE_SOUND, "egg %d screams" % (i + 1))
	bedroom.room_sound.stream = null
	bedroom.calendar_doors[doors[0] - 1].pressed.emit()
	assert_true(bedroom.room_sound.stream == null, "an egg already open stays quiet")


func test_opened_eggs_stay_open_until_a_new_game() -> void:
	BedroomScript.forget_eggs()
	var bedroom := open_bedroom()
	solve_chest(bedroom)
	press(bedroom, "CalendarHotspot")
	var doors := egg_doors_of(bedroom)
	bedroom.calendar_doors[doors[0] - 1].pressed.emit()
	bedroom.calendar_doors[doors[1] - 1].pressed.emit()
	bedroom._leave_popup()
	press(bedroom, "CalendarHotspot")
	assert_eq(bedroom.calendar_doors[doors[0] - 1].icon, bedroom.EGG_ART[0], "still open after closing the calendar")
	assert_eq(bedroom.calendar_doors[doors[1] - 1].icon, bedroom.EGG_ART[1], "both")
	assert_true(bedroom.calendar_doors[doors[2] - 1].icon != bedroom.EGG_ART[2], "a door not opened yet stays closed")

	var again := open_bedroom()  # the same game, the room built again (leave and come back)
	solve_chest(again)
	press(again, "CalendarHotspot")
	assert_eq(again.calendar_doors[doors[0] - 1].icon, again.EGG_ART[0], "still open after coming back")

	var other := open_bedroom(7)  # a new game
	solve_chest(other)
	press(other, "CalendarHotspot")
	for door in egg_doors_of(other):
		assert_true(other.calendar_doors[door - 1].icon not in other.EGG_ART, "a new game starts closed")


func test_the_egg_pictures_exist() -> void:
	for number in range(1, 6):
		var file := "res://assets/images/egg_calendar_%d.png" % number
		assert_true(ResourceLoader.exists(file), file + " exists")
