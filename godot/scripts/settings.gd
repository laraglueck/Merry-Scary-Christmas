# All game numbers and names in one place (game concept, version 2).
# Change values here to make the game easier or harder, not in the rules.
extends RefCounted

# Fuse puzzle
const FUSE_PENALTY_SECONDS := 10
const WIRE_COLOURS := ["blue", "yellow", "white", "black"]
const SYMBOLS := ["star", "bell", "tree", "snowflake"]
# Fuse i belongs to player i and lights one room.
const FUSES := [
	{"colour": "red", "room": "living/dining room"},
	{"colour": "green", "room": "bathroom"},
	{"colour": "gold", "room": "bedroom"},
]

# Network
const NETWORK_PORT := 47411
const MAX_PLAYERS := 3
const JOIN_TIMEOUT_SECONDS := 5.0
const DISCOVERY_PORT := 47412
const DISCOVERY_ADDRESSES := ["255.255.255.255", "127.0.0.1"]  # Wi-Fi broadcast + this computer
const ANNOUNCE_INTERVAL_SECONDS := 0.5
const ROOM_CODE_LENGTH := 4
const ROOM_CODE_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"  # no I and O: easy to read aloud
