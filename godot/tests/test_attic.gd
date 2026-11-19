# Tests for spec 16: the attic screen. They press keys and click like a player.
extends "res://tests/base_test.gd"

const AtticScene = preload("res://scenes/attic.tscn")
const AtticRules = preload("res://scripts/rules/attic_rules.gd")


# Stands in for network.gd in the online test: records what the screen sends.
class FakeNet extends Node:
	signal game_changed
	var game: Dictionary = {}
	var my_index := 0
	var sent: Array = []

	func send_action(action: String, data: Dictionary) -> void:
		sent.append([action, data])


# Opens the attic like starting the scene (this runs _ready).
func open_attic(has_photo := false) -> Node:
	var attic = AtticScene.instantiate()
	attic.seed_value = 42
	attic.has_photo = has_photo
	tree.root.add_child(attic)
	return attic


func key(attic: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	attic._unhandled_input(event)


# The digits that open the lock (without a bedroom, any gold digit counts: 1 stays).
func right_code(attic: Node) -> Array:
	var code := AtticRules.code(attic.game)
	if code[2] == 0:
		code[2] = 1
	return code


# Clicks each dial until it shows the wanted digit.
func set_dials(attic: Node, digits: Array) -> void:
	for i in 3:
		while attic.dial_values()[i] != digits[i]:
			press(attic, "Dial%d" % i)


func open_the_lock(attic: Node) -> void:
	set_dials(attic, right_code(attic))
	press(attic, "TryButton")


# ---------- the lock ----------

func test_starts_with_the_lock_and_all_dials_at_1() -> void:
	var attic := open_attic()
	assert_true(find(attic, "LockPanel").visible, "lock shown")
	assert_true(find(attic, "Jingles").visible, "Jingles seen asleep through the door")
	assert_eq(attic.jingles_picture(), "char_jingles_asleep.png", "asleep")
	assert_eq(attic.dial_values(), [1, 1, 1], "dials")


func test_clicking_a_dial_turns_it_and_wraps_from_9_to_1() -> void:
	var attic := open_attic()
	press(attic, "Dial1")
	assert_eq(attic.dial_values(), [1, 2, 1], "green dial turned")
	assert_eq(text_of(attic, "Dial1"), "2", "dial shows its digit")
	for i in 8:
		press(attic, "Dial1")
	assert_eq(attic.dial_values()[1], 1, "9 wraps to 1")


func test_keys_choose_a_dial_and_turn_it() -> void:
	var attic := open_attic()
	key(attic, "ui_right")
	key(attic, "ui_up")
	key(attic, "ui_up")
	assert_eq(attic.dial_values(), [1, 3, 1], "green dial up twice")
	key(attic, "ui_down")
	key(attic, "ui_down")
	key(attic, "ui_down")
	assert_eq(attic.dial_values(), [1, 9, 1], "down from 1 wraps to 9")


func test_wrong_code_costs_20_seconds_and_keeps_the_lock() -> void:
	var attic := open_attic()
	var wrong := right_code(attic)
	wrong[0] = 1 if wrong[0] != 1 else 2
	set_dials(attic, wrong)
	press(attic, "TryButton")
	assert_eq(attic.game["penalty_seconds"], 20, "penalty")
	assert_contains(text_of(attic, "Message"), "-20 s", "message")
	assert_true(find(attic, "LockPanel").visible, "still locked")


func test_right_code_with_keys_only_shows_jingles_and_the_choices() -> void:
	var attic := open_attic()
	var code := right_code(attic)
	for i in 3:
		while attic.dial_values()[i] != code[i]:
			key(attic, "ui_up")
		key(attic, "ui_right")
	key(attic, "ui_accept")
	assert_true(not find(attic, "LockPanel").visible, "lock gone")
	assert_true(find(attic, "Jingles").visible, "Jingles asleep")
	assert_true(find(attic, "Key").visible, "the key beside him")
	assert_true(find(attic, "ChoiceLockIn").visible, "lock-in choice")
	assert_true(find(attic, "ChoiceReconcile").visible, "photo choice")


# ---------- the choice ----------

func test_photo_choice_is_greyed_out_and_explains_without_the_photo() -> void:
	var attic := open_attic()
	open_the_lock(attic)
	assert_true(find(attic, "ChoiceReconcile").modulate.a < 1.0, "greyed out")
	press(attic, "ChoiceReconcile")
	assert_contains(text_of(attic, "Message"), "nothing that could change his mind", "reason")
	assert_eq(attic.game["phase"], "hall", "game goes on")


func test_lock_in_ends_the_game_as_scary_christmas() -> void:
	var attic := open_attic()
	open_the_lock(attic)
	press(attic, "ChoiceLockIn")
	assert_eq(attic.game["phase"], "scary", "phase")
	assert_true(not find(attic, "Key").visible, "the team took the key")
	assert_contains(text_of(attic, "Message"), "locked Scary Jingles in", "message")


func test_with_the_photo_the_choice_is_open_and_ends_merry() -> void:
	var attic := open_attic(true)
	open_the_lock(attic)
	assert_eq(find(attic, "ChoiceReconcile").modulate.a, 1.0, "not greyed out")
	key(attic, "ui_right")  # from "Lock him in" to the photo
	key(attic, "ui_accept")
	assert_eq(attic.game["phase"], "merry", "phase")


func test_back_to_the_hall() -> void:
	var attic := open_attic()
	press(attic, "BackButton")
	assert_eq(attic.game["location"], "hall", "team back in the hall")


# ---------- online ----------

func test_online_the_code_goes_to_the_host() -> void:
	var net := FakeNet.new()
	tree.root.add_child(net)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	net.game = load("res://scripts/rules/game_rules.gd").new_game(rng)
	net.game["location"] = "attic"
	var attic = AtticScene.instantiate()
	attic.net = net
	tree.root.add_child(attic)
	press(attic, "Dial2")
	press(attic, "TryButton")
	assert_eq(net.sent, [["try_attic_code", {"dials": [1, 1, 2]}]], "sent to the host")


# ---------- effects (spec 20) ----------

func test_he_snores() -> void:
	var attic := open_attic()
	var snore: AudioStreamPlayer = find(attic, "Snore")
	assert_true(snore != null, "snoring is set up")
	assert_eq(snore.stream.loop, true, "it goes on and on")


func test_a_wrong_code_makes_him_stir() -> void:
	var attic := open_attic()
	var wrong := right_code(attic)
	wrong[0] = 1 if wrong[0] != 1 else 2
	set_dials(attic, wrong)
	press(attic, "TryButton")
	assert_eq(attic.jingles_picture(), "char_jingles_awake.png", "awake for a moment")
	assert_true(find(attic, "LockPanel").visible, "still locked")


func test_the_right_code_plays_the_lock() -> void:
	var attic := open_attic()
	open_the_lock(attic)
	assert_true("sfx_key_lock.mp3" in attic.sounds_played, "lock sound")
	assert_eq(attic.jingles_picture(), "char_jingles_asleep.png", "still asleep")


func test_online_a_teammates_wrong_code_makes_him_stir_here_too() -> void:
	var net := FakeNet.new()
	tree.root.add_child(net)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	net.game = load("res://scripts/rules/game_rules.gd").new_game(rng)
	net.game["location"] = "attic"
	var attic = AtticScene.instantiate()
	attic.net = net
	tree.root.add_child(attic)
	net.game["penalty_seconds"] += 20  # a teammate tried a wrong code
	net.game_changed.emit()
	assert_eq(attic.jingles_picture(), "char_jingles_awake.png", "awake for a moment")
