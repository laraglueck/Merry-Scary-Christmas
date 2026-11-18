extends Control

const GameRules = preload("res://scripts/rules/game_rules.gd")
const FuseRules = preload("res://scripts/rules/fuse_rules.gd")

const IMAGES := "res://assets/images/"
const RED_FUSE := 0

@export var seed_value := -1
@export var red_fuse_on := true

var net: Node = null
var game: Dictionary
var _background: TextureRect


func _ready() -> void:
	if net != null:
		game = net.game
		net.game_changed.connect(_on_game_changed)
	else:
		game = _offline_game()

	_background = TextureRect.new()
	_background.name = "Background"
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_refresh()


func _offline_game() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	var local_game := GameRules.new_game(rng)
	local_game["location"] = "living_room"

	if red_fuse_on:
		var wires: Array = local_game["puzzle"]["fuses"][RED_FUSE]["order"].duplicate()
		FuseRules.try_fuse(local_game["puzzle"], RED_FUSE, wires)

	local_game["last_event"] = ""
	return local_game


func _on_game_changed() -> void:
	game = net.game
	_refresh()


func _refresh() -> void:
	if game.is_empty():
		return

	var lit: bool = game["puzzle"]["fuses"][RED_FUSE]["solved"]
	var picture := "room_living_room_lit.webp" if lit else "room_living_room_dark.webp"
	_background.texture = load(IMAGES + picture)
    