# Every asset file the game expects (spec 06, names from the shared contract).
# One list for everything: the placeholder script uses it now, the asset test
# and the preview scene will use it later. Add a new asset here first.
extends RefCounted

const IMAGE_DIR := "res://assets/images/"
const SOUND_DIR := "res://assets/sounds/"

# Image sizes in pixels (width, height).
const SIZE_SCREEN := Vector2i(1920, 1080)
const SIZE_CHARACTER := Vector2i(500, 800)
const SIZE_ITEM := Vector2i(512, 512)
const SIZE_ICON := Vector2i(128, 128)
const SIZE_CANDLE := Vector2i(128, 256)
const SIZE_STEAM := Vector2i(256, 256)
const SIZE_BOARD := Vector2i(256, 128)
const SIZE_BAR := Vector2i(512, 128)

# Rooms that a fuse lights up: each has a dark and a lit background.
const FUSE_ROOMS := ["living_room", "bathroom", "bedroom"]


# File name -> size, for every image.
static func images() -> Dictionary:
	var list := {}

	# Backgrounds
	list["room_garden.webp"] = SIZE_SCREEN
	list["room_hall.webp"] = SIZE_SCREEN
	list["room_attic.webp"] = SIZE_SCREEN
	for room in FUSE_ROOMS:
		list["room_%s_dark.webp" % room] = SIZE_SCREEN
		list["room_%s_lit.webp" % room] = SIZE_SCREEN
	list["room_bathroom_drained.webp"] = SIZE_SCREEN  # lit, the tub empty after the taps are solved

	# Characters
	for character in ["elf", "snowman", "gingerbread", "santa_asleep", "santa_awake", "nutcracker"]:
		list["char_%s.png" % character] = SIZE_CHARACTER
	# The same figures with a green or yellow scarf / jacket (the first ones wear red).
	for character in ["santa", "snowman", "nutcracker"]:
		for colour in ["green", "yellow"]:
			list["char_%s_%s.png" % [character, colour]] = SIZE_CHARACTER

	# Items
	for colour in ["red", "green", "gold"]:
		list["item_fuse_%s.png" % colour] = SIZE_ITEM
	for number in range(1, 4):
		list["item_gift_%d.png" % number] = SIZE_ITEM
	list["item_key.png"] = SIZE_ITEM
	list["item_house_plan.png"] = SIZE_ITEM

	# Changing parts that sit on top of a room background
	list["prop_candle_lit.png"] = SIZE_CANDLE
	list["prop_candle_out.png"] = SIZE_CANDLE
	for digit in range(1, 10):
		list["prop_steam_%d.png" % digit] = SIZE_STEAM
	list["prop_calendar_open.png"] = SIZE_ICON
	list["prop_calendar_closed.png"] = SIZE_ICON
	list["prop_board.png"] = SIZE_BOARD

	# Symbols and wires of the fuse puzzle (same names as in settings.gd)
	for symbol in ["star", "bell", "tree", "snowflake"]:
		list["sym_%s.png" % symbol] = SIZE_ICON
	for wire in ["blue", "yellow", "white", "black"]:
		list["wire_%s.png" % wire] = SIZE_ICON

	# Interface
	list["ui_title.webp"] = SIZE_SCREEN
	list["ui_win.webp"] = SIZE_SCREEN
	list["ui_lose.webp"] = SIZE_SCREEN
	list["ui_fuse_box.webp"] = SIZE_SCREEN  # close-up shown when the fuse box is opened
	list["ui_house_plan.webp"] = SIZE_SCREEN  # close-up of the house plan, with an empty box for the legend
	list["ui_clock.png"] = SIZE_BOARD
	list["ui_inventory.png"] = SIZE_BAR
	list["ui_noise_meter.png"] = SIZE_BAR
	return list


# Every sound file.
static func sounds() -> Array:
	var list := []
	for effect in ["fuse_click", "spark", "creak", "snore", "wind", "bells", "gift", "scare", "win", "lose",
			"faucet", "clock_tick", "clock_wrong", "clock_chime", "door_unlock", "key_lock",
			"easter_egg", "rain", "storm"]:
		list.append("sfx_%s.mp3" % effect)
	list.append("music_lobby.mp3")
	list.append("music_house.mp3")
	list.append("voice_title.mp3")  # spoken intro on the title screen
	return list
