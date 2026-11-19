extends "res://tests/base_test.gd"

const BedroomScene = preload("res://scenes/bedroom.tscn")
const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")


func test_gold_digit_is_always_valid_and_legacy_zero_is_checked() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in range(100):
		rng.seed = seed_value
		var room := BedroomRules.create_room(rng)
		assert_true(int(room["digit"]) in range(1, 10), "gold digit for seed %d" % seed_value)
	var game := GameRules.new_game(rng)
	game["bedroom"]["digit"] = 0
	var code := AtticRules.code(game)
	assert_eq(code[2], 1, "legacy zero displays as a valid gold dial")
	var wrong := code.duplicate()
	wrong[2] = 2
	assert_eq(AtticRules.try_code(AtticRules.create(), wrong, code)["correct"], false, "another gold digit is rejected")


func test_host_checks_bedroom_light_and_location() -> void:
	var game := GameRules.new_game(RandomNumberGenerator.new())
	var solution: Array = game["bedroom"]["wheels"]
	GameRules.apply(game, 0, "set_wheels", {"symbols": solution})
	assert_contains(game["last_event"], "enter the bedroom")
	game["location"] = "bedroom"
	GameRules.apply(game, 0, "set_wheels", {"symbols": solution})
	assert_contains(game["last_event"], "too dark")
	assert_eq(game["bedroom"]["solved"], false)
	assert_eq(game["penalty_seconds"], 0)


func test_standalone_bedroom_calendar_chest_and_shared_items() -> void:
	var bedroom = BedroomScene.instantiate()
	bedroom.seed_value = 42
	tree.root.add_child(bedroom)
	var game: Dictionary = bedroom.offline_game
	var room: Dictionary = game["bedroom"]
	var clue: Dictionary = game["living_room"]
	assert_true(bedroom.bedroom_is_lit, "standalone room is lit")

	press(bedroom, "CalendarHotspot")
	assert_eq(bedroom.current_popup, "calendar")
	assert_eq(bedroom.calendar_doors.filter(func(door): return not door.disabled).size(), 2)
	bedroom.calendar_doors[int(clue["hour"]) - 1].pressed.emit()
	assert_eq(bedroom.clue_picture.texture, bedroom.SHORT_HAND)
	var photo_door := BedroomRules.photo_door(room, clue)
	assert_true(photo_door not in [clue["hour"], clue["minute"]])
	GameRules.apply(game, 0, "take_photo", {})
	GameRules.apply(game, 0, "take_gift", {"room": "bedroom"})
	assert_eq(game["inventory"], [], "items remain locked")

	bedroom._leave_popup()
	press(bedroom, "ChestHotspot")
	var wrong: Array = room["wheels"].duplicate()
	wrong[0] = "bell" if wrong[0] == "star" else "star"
	for i in 3:
		bedroom.wheels[i].select(BedroomRules.SYMBOLS.find(wrong[i]))
	bedroom.chest_button.pressed.emit()
	assert_eq(game["penalty_seconds"], 20)
	assert_eq(room["solved"], false)

	for i in 3:
		bedroom.wheels[i].select(BedroomRules.SYMBOLS.find(room["wheels"][i]))
	bedroom.chest_button.pressed.emit()
	assert_true(room["solved"] and bedroom.digit_label.visible)
	assert_contains(bedroom.digit_label.text, str(AtticRules.code(game)[2]))
	bedroom.gift_button.pressed.emit()
	assert_eq(bedroom.gift_button.visible, false)
	bedroom._leave_popup()
	press(bedroom, "CalendarHotspot")
	assert_true(bedroom.calendar_doors.all(func(door): return not door.disabled))
	bedroom.calendar_doors[photo_door - 1].pressed.emit()
	assert_true(bedroom.photo_picture.visible)
	bedroom.photo_button.pressed.emit()
	assert_eq(bedroom.photo_button.visible, false)
	GameRules.apply(game, 0, "take_photo", {})
	GameRules.apply(game, 0, "take_gift", {"room": "bedroom"})
	assert_eq(game["inventory"], ["gift_3", "photo_piece_3"], "items are awarded once")
