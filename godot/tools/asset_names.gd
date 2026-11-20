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
const SIZE_PART := Vector2i(256, 256)

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
	for character in ["santa", "snowman", "nutcracker", "jingles_asleep", "jingles_peek", "jingles_awake"]:  # three heroes, then the villain Scary Jingles
		list["char_%s.png" % character] = SIZE_CHARACTER
	# The same figures with a green or yellow scarf / jacket (the first ones wear red).
	for character in ["santa", "snowman", "nutcracker"]:
		for colour in ["green", "yellow"]:
			list["char_%s_%s.png" % [character, colour]] = SIZE_CHARACTER
	# Spec 27: every figure in every colour with an accessory (bow, red nose, antlers).
	# Red has no colour in the name, like above: char_santa_bow.png, char_santa_green_bow.png.
	for character in ["santa", "snowman", "nutcracker"]:
		for colour in ["", "_green", "_yellow"]:
			for accessory in ["bow", "nose", "antlers"]:
				list["char_%s%s_%s.png" % [character, colour, accessory]] = SIZE_CHARACTER

	# Items
	for colour in ["red", "green", "gold"]:
		list["item_fuse_%s.png" % colour] = SIZE_ITEM
	for number in range(1, 4):
		list["item_gift_%d.png" % number] = SIZE_ITEM
	list["item_key.png"] = SIZE_ITEM
	list["item_house_plan.png"] = SIZE_ITEM
	list["item_photo.png"] = SIZE_ITEM    # Santa and the elf as friends, behind a bedroom calendar door
	for piece in range(1, 4):  # the photo torn in three (spec 21), cut by tools/cut_photo.gd
		list["item_photo_piece_%d.png" % piece] = SIZE_ITEM
	list["item_cookies.png"] = SIZE_ITEM  # left for Scary Jingles in the Merry ending

	# Changing parts that sit on top of a room background
	list["prop_candle_lit.png"] = SIZE_CANDLE
	list["prop_candle_out.png"] = SIZE_CANDLE
	for digit in range(1, 10):
		list["prop_steam_%d.png" % digit] = SIZE_STEAM
	list["prop_calendar_open.png"] = SIZE_ICON
	list["prop_calendar_closed.png"] = SIZE_ICON
	list["prop_board.png"] = SIZE_BOARD
	list["prop_steam.png"] = Vector2i(960, 720)  # steam over the bathroom mirror (soft, so small is enough)
	list["prop_clock_face.png"] = SIZE_ITEM  # the living room clock lock: face and two hands
	list["prop_clock_hand_short.png"] = SIZE_PART
	list["prop_clock_hand_long.png"] = SIZE_PART
	list["prop_note.png"] = SIZE_PART
	list["prop_wheel.png"] = SIZE_PART  # one symbol wheel of the bedroom chest
	list["prop_doll.png"] = SIZE_CHARACTER
	list["prop_doll_turned.png"] = SIZE_CHARACTER  # the same doll, head turned (jumpscare, later)
	list["prop_moon_full.png"] = SIZE_PART      # the moon in the garden sky (later)
	list["prop_mirror_face.png"] = SIZE_ITEM    # the face in the bathroom mirror (later)

	# Symbols and wires of the fuse puzzle (same names as in settings.gd)
	for symbol in ["star", "bell", "tree", "snowflake"]:
		list["sym_%s.png" % symbol] = SIZE_ICON
	for wire in ["blue", "yellow", "white", "black"]:
		list["wire_%s.png" % wire] = SIZE_ICON

	# Interface
	list["ui_title.webp"] = SIZE_SCREEN
	list["ui_win.webp"] = SIZE_SCREEN
	list["ui_win_merry.webp"] = SIZE_SCREEN  # Merry Christmas ending (photo and cookies left)
	list["ui_win_scary.webp"] = SIZE_SCREEN  # Scary Christmas ending (elf locked in)
	list["ui_lose.webp"] = SIZE_SCREEN
	list["ui_fuse_box.webp"] = SIZE_SCREEN  # close-up shown when the fuse box is opened
	list["ui_fuse_box_on.webp"] = SIZE_SCREEN  # the same box with all breakers up (tools/make_fuse_box.gd)
	list["ui_house_plan.webp"] = SIZE_SCREEN  # close-up of the house plan, with an empty box for the legend
	list["ui_clock.png"] = SIZE_PART       # the pocket watch, top right
	list["ui_clock_hand.png"] = SIZE_PART  # its hand, turned by the game
	list["ui_scare_face.webp"] = SIZE_SCREEN  # jumpscare (later)
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
