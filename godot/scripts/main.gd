# Main scene (spec 04, 07, 11): keeps the network connection and shows the right screen:
# the title (on this device only, until "Start"), the lobby before the game starts,
# then the place where the team is (hall, a room, the attic). If the host leaves,
# everyone is back in the lobby.
#
# TEAM: your room's scene = a new entry in SCREENS (key = its place, e.g. "bedroom").
# Until then the place shows PLACEHOLDER with its name and "Back to the hall".
extends Node

const NetworkScript = preload("res://scripts/net/network.gd")
const SCREENS := {
	"title": preload("res://scenes/title.tscn"),
	"lobby": preload("res://scenes/lobby.tscn"),
	"hall": preload("res://scenes/hall.tscn"),
	"bathroom": preload("res://scenes/bathroom.tscn"),
}
const PLACEHOLDER = preload("res://scenes/placeholder_room.tscn")

var net: Node
var screen: Node
var screen_name := ""
var title_done := false  # "Start" pressed, or a game already started on this device


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	net.changed.connect(_update_screen)
	net.game_changed.connect(_update_screen)
	_update_screen()


# Before "Start" -> title; no game yet (or game over) -> lobby; in the house -> where
# the team is; later phases (e.g. an end screen) -> that phase.
func current_screen() -> String:
	if net.game.is_empty():
		return "lobby" if title_done else "title"
	var phase: String = net.game.get("phase", "hall")
	if phase == "hall":
		return net.game.get("location", "hall")
	return phase


func _on_title_start_pressed() -> void:
	title_done = true
	_update_screen()


func _update_screen() -> void:
	if not net.game.is_empty():
		title_done = true  # once a game ran here, game over leads back to the lobby
	var wanted := current_screen()
	if wanted == screen_name:
		return
	if screen != null:
		screen.queue_free()  # removed at the end of this frame
	screen = SCREENS.get(wanted, PLACEHOLDER).instantiate()
	screen.net = net
	if "place" in screen:
		screen.place = wanted
	if screen.has_signal("start_pressed"):
		screen.start_pressed.connect(_on_title_start_pressed)
	add_child(screen)
	screen_name = wanted
