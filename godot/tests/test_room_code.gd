# Tests for spec 03b: room codes and the announcement message (pure functions).
extends "res://tests/base_test.gd"

const RoomCode = preload("res://scripts/net/room_code.gd")
const Settings = preload("res://scripts/settings.gd")


func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_code_has_4_allowed_letters() -> void:
	for seed_value in [1, 2, 3, 4, 5]:
		var code: String = RoomCode.make_code(make_rng(seed_value))
		assert_eq(code.length(), 4, "length of '%s'" % code)
		for letter in code:
			assert_true(letter in Settings.ROOM_CODE_LETTERS, "'%s' allowed" % letter)


func test_same_seed_same_code_different_seeds_differ() -> void:
	assert_eq(RoomCode.make_code(make_rng(42)), RoomCode.make_code(make_rng(42)), "seed 42 twice")
	var seen := {}
	for seed_value in [1, 2, 3, 4, 5]:
		seen[RoomCode.make_code(make_rng(seed_value))] = true
	assert_true(seen.size() > 1, "5 seeds give more than one code")


func test_valid_codes() -> void:
	for text in ["KRTW", "krtw", "  KrTw "]:
		assert_eq(RoomCode.is_valid_code(text), true, "'%s' valid" % text)


func test_invalid_codes() -> void:
	for text in ["", "KRT", "KRTWX", "KR1W", "KRIW", "KROW", "192.168.1.42"]:
		assert_eq(RoomCode.is_valid_code(text), false, "'%s' invalid" % text)


func test_announce_message_round_trip() -> void:
	var message: String = RoomCode.announce_message("KRTW", 47411)
	assert_eq(message, "MSC1|KRTW|47411", "message")
	assert_eq(RoomCode.parse_announce(message), {"code": "KRTW", "port": 47411}, "parsed")


func test_parse_ignores_other_messages() -> void:
	for text in ["hello", "MSC1|KRTW", "MSC1|KRTW|abc", "XYZ|KRTW|47411", "MSC1|KR1W|47411"]:
		assert_eq(RoomCode.parse_announce(text), {}, "'%s' ignored" % text)
