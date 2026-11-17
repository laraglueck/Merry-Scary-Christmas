# Main scene (spec 04, 07, 11, 12): keeps the network connection and shows the right
# screen: on this device only, the loading screen with the story, then the title (until
# "Start"); the lobby before the game starts, then the place where the team is (hall, a
# room, the attic). If the host leaves, everyone is back in the lobby.
# The music plays here, so it goes on from screen to screen until the game starts.
#
# TEAM: your room's scene = a new entry in SCREENS (key = its place, e.g. "bedroom").
# Until then the place shows PLACEHOLDER with its name and "Back to the hall".
extends Node

const NetworkScript = preload("res://scripts/net/network.gd")
const SCREENS := {
	"intro": preload("res://scenes/intro.tscn"),
	"title": preload("res://scenes/title.tscn"),
	"lobby": preload("res://scenes/lobby.tscn"),
	"hall": preload("res://scenes/hall.tscn"),
	"bathroom": preload("res://scenes/bathroom.tscn"),
}
const PLACEHOLDER = preload("res://scenes/placeholder_room.tscn")

var net: Node
var screen: Node
var screen_name := ""
var intro_done := false  # story finished or skipped, or a game already started here
var title_done := false  # "Start" pressed, or a game already started on this device
var music: AudioStreamPlayer


func _ready() -> void:
	net = NetworkScript.new()
	net.name = "Network"
	add_child(net)
	_start_music()
	net.changed.connect(_update_screen)
	net.game_changed.connect(_update_screen)
	_update_screen()


# First the story, then before "Start" -> title; no game yet (or game over) -> lobby; in the house -> where
# the team is; later phases (e.g. an end screen) -> that phase.
func current_screen() -> String:
	if net.game.is_empty():
		if not intro_done:
			return "intro"
		return "lobby" if title_done else "title"
	var phase: String = net.game.get("phase", "hall")
	if phase == "hall":
		return net.game.get("location", "hall")
	return phase


func _on_intro_finished() -> void:
	intro_done = true
	_update_screen()


func _on_title_start_pressed() -> void:
	title_done = true
	_update_screen()


func _update_screen() -> void:
	if not net.game.is_empty():
		intro_done = true  # once a game ran here, game over leads back to the lobby
		title_done = true
		music.stop()  # the music belongs to the screens before the game
	var wanted := current_screen()
	if wanted == screen_name:
		return
	if screen != null:
		screen.queue_free()  # removed at the end of this frame
	screen = SCREENS.get(wanted, PLACEHOLDER).instantiate()
	screen.net = net
	if "place" in screen:
		screen.place = wanted
	if screen.has_signal("finished"):
		screen.finished.connect(_on_intro_finished)
	if screen.has_signal("start_pressed"):
		screen.start_pressed.connect(_on_title_start_pressed)
	add_child(screen)
	screen_name = wanted


# The menu music (loops): loading screen, title and lobby, without a break between them.
func _start_music() -> void:
	music = AudioStreamPlayer.new()
	music.name = "Music"
	var stream: AudioStreamMP3 = load("res://assets/sounds/music_lobby.mp3")
	stream.loop = true
	music.stream = stream
	# Not in the headless test run: no sound card there, and a sound still playing at
	# the end shows up as a leak warning.
	music.autoplay = DisplayServer.get_name() != "headless"
	add_child(music)
