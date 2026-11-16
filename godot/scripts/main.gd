# Main scene (spec 04): keeps the network connection and shows the screen for
# the current phase of the shared game: the lobby before the game starts,
# then the hall. If the host leaves, everyone is back in the lobby.
#
# TEAM: a new phase (rooms, attic, end) = a new entry in SCREENS.
extends Node

const NetworkScript = preload("res://scripts/net/network.gd")
const SCREENS := {
	"lobby": preload("res://scenes/lobby.tscn"),
	"hall": preload("res://scenes/hall.tscn"),
}

var net: Node
var screen: Node
var screen_name := ""


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	net.changed.connect(_update_screen)
	net.game_changed.connect(_update_screen)
	_update_screen()


# No game yet (or game over) -> lobby; otherwise the phase in the game.
func current_phase() -> String:
	return net.game.get("phase", "lobby")


func _update_screen() -> void:
	var wanted := current_phase()
	if wanted == screen_name or not SCREENS.has(wanted):
		return
	if screen != null:
		screen.queue_free()  # removed at the end of this frame
	screen = SCREENS[wanted].instantiate()
	screen.net = net
	add_child(screen)
	screen_name = wanted
