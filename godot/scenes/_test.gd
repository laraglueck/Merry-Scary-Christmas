
extends Control

const BedroomScene = preload("res://scenes/bedroom.tscn")
const GameRules = preload("res://scripts/rules/game_rules.gd")

signal game_changed

var game: Dictionary = {}
var bedroom: Control


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Create a complete game state.
	game = GameRules.new_game(rng)

	# Start directly in the bedroom.
	game["location"] = "bedroom"

	# Activate the bedroom fuse for testing.
	for fuse in game["puzzle"]["fuses"]:
		if fuse["room"] == "bedroom":
			fuse["solved"] = true

	print("================================")
	print("BEDROOM TEST MODE")
	print("Bedroom location: ", game["location"])
	print("Toy chest solution: ", game["bedroom"]["wheels"])
	print("Clock hour: ", game["living_room"]["hour"])
	print("Clock minute: ", game["living_room"]["minute"])
	print("================================")

	# Instantiate the actual bedroom scene.
	bedroom = BedroomScene.instantiate()

	# Connect the fake network BEFORE adding the scene.
	bedroom.net = self
	add_child(bedroom)

	# Refresh the bedroom interface.
	game_changed.emit()


func send_action(action: String, data: Dictionary) -> void:
	GameRules.apply(game, 2, action, data)

	print("Action: ", action)
	print("Last event: ", game.get("last_event", ""))
	print("Inventory: ", game.get("inventory", []))
	print("Penalty: ", game.get("penalty_seconds", 0))

	game_changed.emit()
