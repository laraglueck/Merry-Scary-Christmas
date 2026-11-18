
extends Control

const BedroomRules = preload("res://scripts/rules/bedroom_rules.gd")
const SYMBOLS = ["star", "bell", "tree", "snowflake"]

@onready var toy_chest_button: Button = $VBoxContainer/ToyChestButton
@onready var calendar_button: Button = $VBoxContainer/CalendarButton
@onready var gift_button: Button = $VBoxContainer/GiftButton
@onready var photo_button: Button = $VBoxContainer/PhotoButton

@onready var wheel_1: OptionButton = $VBoxContainer/Wheel1
@onready var wheel_2: OptionButton = $VBoxContainer/Wheel2
@onready var wheel_3: OptionButton = $VBoxContainer/Wheel3

var test_room: Dictionary = {}
var test_inventory: Array[String] = []
var penalty_seconds: int = 0
var status_label: Label


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	test_room = BedroomRules.create_room(rng)

	for wheel in [wheel_1, wheel_2, wheel_3]:
		wheel.clear()
		for symbol in SYMBOLS:
			wheel.add_item(symbol.capitalize())

	toy_chest_button.pressed.connect(_on_toy_chest_pressed)
	calendar_button.pressed.connect(_on_calendar_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	photo_button.pressed.connect(_on_photo_pressed)

	status_label = Label.new()
	status_label.text = "Explore the bedroom."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$VBoxContainer.add_child(status_label)

	_update_buttons()


func _on_toy_chest_pressed() -> void:
	if test_room["solved"]:
		_show_message("The toy chest is already open.")
		return

	var selected_symbols = [
		SYMBOLS[wheel_1.selected],
		SYMBOLS[wheel_2.selected],
		SYMBOLS[wheel_3.selected]
	]

	var result = BedroomRules.try_wheels(test_room, selected_symbols)

	if result["error"] != "":
		_show_message(result["error"])
	elif result["correct"]:
		_show_message("Correct! The toy chest opens!")
	else:
		penalty_seconds += result["penalty_seconds"]
		_show_message(
			"Wrong combination! -20 seconds. Total penalty: %d seconds."
			% penalty_seconds
		)

	_update_buttons()


func _on_calendar_pressed() -> void:
	_show_message(
		"Two Advent calendar doors are open. "
		+ "Their clues reveal the clock positions."
	)


func _on_gift_pressed() -> void:
	var result = BedroomRules.take_gift(test_room)

	if result["ok"]:
		test_inventory.append("gift_3")
		_show_message("You found Present 3! Inventory: %s" % str(test_inventory))
	else:
		_show_message(result["error"])

	_update_buttons()


func _on_photo_pressed() -> void:
	var result = BedroomRules.take_photo(test_room)

	if result["ok"]:
		test_inventory.append("photo")
		_show_message(
			"You found an old photograph of Santa and Scary Jingles!"
		)
	else:
		_show_message(result["error"])

	_update_buttons()


func _update_buttons() -> void:
	gift_button.disabled = not test_room["solved"] or test_room["gift_taken"]
	photo_button.disabled = test_room["photo_taken"]
	toy_chest_button.disabled = test_room["solved"]


func _show_message(message: String) -> void:
	status_label.text = message
	print(message)
