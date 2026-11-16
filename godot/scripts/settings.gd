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
