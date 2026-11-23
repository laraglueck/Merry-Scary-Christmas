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

# Attic (spec 16): a wrong code on the three dials costs time.
const ATTIC_PENALTY_SECONDS := 20


# Music volumes (spec 22), in decibels: 0 = as loud as the file, -6 = about half as loud.
const MENU_MUSIC_DB := -10.0    # music_lobby.mp3: intro, title, lobby
const HOUSE_MUSIC_DB := -18.0   # music_house.mp3: quietly under the rooms while the game runs
const STORY_LEAD_IN_SECONDS := 2.0  # the story fades in from black before the voice starts (spec 23)

# The team, shown on the credits screen after the ending (spec 34).
const TEAM := [
	{"name": "Gloria Bogea Heinzel", "number": "79191"},
	{"name": "Lara Victoria Glück", "number": "70426"},
	{"name": "Leon Blieffert", "number": "73695"},
	{"name": "Carl Mathies Rumohr", "number": "71317"},
	{"name": "Mika Nolte", "number": "71772"},
]
const COURSE := "Nova SBE · Introduction to Programming · Fall 2026"

# The clock (spec 13)
const GAME_SECONDS := 1200           # 20 minutes until midnight (second test round: 10 were too short)
const CLOCK_WARNING_SECONDS := 60    # the last minute: the clock turns red

# The inventory (spec 14): everything the team can find, in the order the bar shows it.
const ITEMS := [
	{"id": "gift_1", "name": "Present 1", "picture": "item_gift_1.png"},  # living room (Gloria)
	{"id": "gift_2", "name": "Present 2", "picture": "item_gift_2.png"},  # bathroom
	{"id": "gift_3", "name": "Present 3", "picture": "item_gift_3.png"},  # bedroom (Leon)
	{"id": "photo_piece_1", "name": "Torn piece", "picture": "item_photo_piece_1.png"},  # living room (spec 21)
	{"id": "photo_piece_2", "name": "Torn piece", "picture": "item_photo_piece_2.png"},  # bathroom
	{"id": "photo_piece_3", "name": "Torn piece", "picture": "item_photo_piece_3.png"},  # bedroom calendar
	{"id": "photo", "name": "Photo", "picture": "item_photo.png"},         # bedroom calendar
	{"id": "cookies", "name": "Cookies", "picture": "item_cookies.png"},   # living room tin (spec 31)
	{"id": "key", "name": "Key", "picture": "item_key.png"},              # attic (spec 16)
]

# Character selection (spec 18): the figures and their scarf/jacket colours.
# The pictures are char_<id>.png (red) and char_<id>_<colour>.png (green, yellow).
# Each hero has one power, usable once per game (hero powers): what it is called and does.
const CHARACTERS := [
	{"id": "santa", "name": "Santa", "power": "hint", "power_name": "Ho ho hint",
		"power_text": "A tip for the room you are in"},
	{"id": "snowman", "name": "Snowman", "power": "freeze", "power_name": "Freeze",
		"power_text": "Freezes the clock: +30 seconds"},
	{"id": "nutcracker", "name": "Nutcracker", "power": "crack", "power_name": "Crack",
		"power_text": "Cracks one part of the answer"},
]
const FREEZE_SECONDS := 30  # the snowman's power
const POWER_MESSAGE_SECONDS := 15.0  # how long the box under the power button shows what a power did
const NAME_LENGTH := 20     # team or player name for the leaderboard
# Help in three levels: gentle hints in the rooms, a hero's power whenever the team wants,
# and a rescue hint (almost the answer) only after this many wrong tries.
const RESCUE_TRIES := 5
const CHARACTER_COLOURS := [
	{"id": "red", "name": "Red", "dot": Color("b3262a")},
	{"id": "green", "name": "Green", "dot": Color("2f7d3a")},
	{"id": "yellow", "name": "Yellow", "dot": Color("e0b83a")},
]

# Accessories (spec 18): a placeholder until the pictures are drawn. Add entries here, with
# a "picture" (shown on the figure), and the arrows on the selection screen page through them.
const ACCESSORIES := [  # spec 27: one picture per figure, colour and accessory
	{"id": "none", "name": "None"},
	{"id": "bow", "name": "Bow"},
	{"id": "nose", "name": "Red nose"},
]

# Walking figures (spec 19): WASD, in pixels of the room picture per second.
const WALK_SPEED := 260.0          # left and right
const WALK_SPEED_DEPTH := 130.0    # into the room and back is slower (it looks further away)
const FIGURE_SYNC_SECONDS := 0.1   # the host tells everybody where the figures are this often
const FIGURE_START_X := [520.0, 688.0, 856.0]  # Player 1, 2, 3 side by side in the hall
const FIGURE_START_Y := 690.0
# Where the feet may stand in the hall: a polygon in pixels of room_hall.webp (1376 x 768), far
# left point first. Wide at the front, narrow at the back; the notch in the middle is the stairs.
# Press F3 in the game to see it over the picture; move the points if the figure walks into a wall.
const FLOOR_HALL := [
	Vector2(530, 500), Vector2(690, 500), Vector2(720, 572), Vector2(985, 578), Vector2(1180, 692),
	Vector2(1376, 748), Vector2(1376, 768), Vector2(40, 768), Vector2(180, 690), Vector2(380, 572),
]
const FAR_SCALE := 0.7             # a figure at the far edge is drawn this big (1 = at the front)

# Save and resume (spec 15): the host's save file, in Godot's data folder (not the repo).
# Tests use another file: the environment variable MERRY_SCARY_SAVE (see run_tests.gd).
const SAVE_PATH := "user://saved_game.save"

# The real weather (spec 26): the elf's house is in Greenland. Open-Meteo, free, no key.
const WEATHER_PLACE := "Nuuk, Greenland"
const WEATHER_LATITUDE := 64.18
const WEATHER_LONGITUDE := -51.69
const WEATHER_TIMEOUT_SECONDS := 4.0
const WINDOW_WIPE_SECONDS := 3.5  # the frost is wiped off the window this slowly, then the weather shows

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
