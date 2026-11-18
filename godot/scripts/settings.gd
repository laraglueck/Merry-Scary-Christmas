# All game numbers and names in one place (game concept, version 2).
# Change values here to make the game easier or harder, not in the rules.
extends RefCounted

# Fuse puzzle
const FUSE_PENALTY_SECONDS := 10
const WIRE_COLOURS := ["blue", "yellow", "white", "black"]
const SYMBOLS := ["star", "bell", "tree", "snowflake"]
# Fuse i belongs to player i and lights one room.
const FUSES := [
	{"colour": "red", "room": "living/dining room", "place": "living_room"},
	{"colour": "green", "room": "bathroom", "place": "bathroom"},
	{"colour": "gold", "room": "bedroom", "place": "bedroom"},
]

# Bathroom (spec 10): four turns of the taps, each hot or cold.
const TAPS := ["hot", "cold"]
const TAP_TURNS := 4
const TAP_PENALTY_SECONDS := 20
# Living room: a wrong clock setting costs time.
const LIVING_ROOM_PENALTY_SECONDS := 20


# The clock (spec 13)
const GAME_SECONDS := 600            # 10 minutes until midnight
const CLOCK_WARNING_SECONDS := 60    # the last minute: the clock turns red

# The inventory (spec 14): everything the team can find, in the order the bar shows it.
const ITEMS := [
	{"id": "gift_1", "name": "Present 1", "picture": "item_gift_1.png"},  # living room (Gloria)
	{"id": "gift_2", "name": "Present 2", "picture": "item_gift_2.png"},  # bathroom
	{"id": "gift_3", "name": "Present 3", "picture": "item_gift_3.png"},  # bedroom (Leon)
	{"id": "photo", "name": "Photo", "picture": "egg_young_santa.png"},   # bedroom calendar (Leon)
	{"id": "key", "name": "Key", "picture": "item_key.png"},              # attic (Lara)
]

# Save and resume (spec 15): the host's save file, in Godot's data folder (not the repo).
# Tests use another file: the environment variable MERRY_SCARY_SAVE (see run_tests.gd).
const SAVE_PATH := "user://saved_game.save"

# Network
const NETWORK_PORT := 47411
const MAX_PLAYERS := 3
const JOIN_TIMEOUT_SECONDS := 5.0
const DISCOVERY_PORT := 47412
const DISCOVERY_ADDRESSES := ["255.255.255.255", "127.0.0.1"]  # Wi-Fi broadcast + this computer
const ANNOUNCE_INTERVAL_SECONDS := 0.5
const ROOM_CODE_LENGTH := 4
const ROOM_CODE_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"  # no I and O: easy to read aloud

# Hall atmosphere
const FLICKER_MAX_DARKNESS := 0.25      # 0 = no flicker, 1 = completely dark
const FLICKER_PAUSE_MIN_SECONDS := 0.6   # calm time between two bursts
const FLICKER_PAUSE_MAX_SECONDS := 1.8
const TITLE_FLICKER_DARKNESS := 0.9   # title screen (spec 11): the window light almost goes out

# Walking through the house (spec 07): where the team can be.
const PLACES := ["hall", "living_room", "bathroom", "bedroom", "attic"]
