# Tests for spec 34: languages.
extends "res://tests/base_test.gd"

const Lang = preload("res://scripts/lang.gd")


const SAMPLE := {
	"Start": "Start",
	"Player %d": "Spieler %d",
	"%s: wrong order, -%d s": "%s: falsche Reihenfolge, -%d s",
	"%s: %s": "%s: %s",
	"the bathroom is too dark": "das Bad ist zu dunkel",
	"%s took %s": "%2$s nahm %1$s",
}


func _german() -> Lang.TemplateTranslation:
	return Lang.TemplateTranslation.from_catalog("de", SAMPLE)



# The fuse hint names the fuse's shape (spec 34): the shape is translated as a part.
func test_the_fuse_hint_and_credits_are_translated() -> void:
	var de := Lang.TemplateTranslation.from_catalog("de", load(Lang.CATALOGS["de"]).TEXTS)
	var hint := "[b]Sparks![/b] Look at the frame: these symbols belong to the %s fuse (%s). Who has it?" % ["GOLD", "diamond"]
	assert_contains(de.translate(hint), "Sicherung GOLD (Raute)", "German hint with the shape")
	assert_eq(de.translate("Made by"), "Gemacht von", "credits")

func test_a_plain_text_is_translated() -> void:
	assert_eq(_german().translate("Start"), "Start", "same word")
	assert_eq(_german().translate("Player 2"), "Spieler 2", "with a number")
	assert_eq(_german().translate("Something nobody wrote"), "Something nobody wrote", "unknown stays English")


func test_a_rule_message_is_translated_part_by_part() -> void:
	assert_eq(_german().translate("Player 2: wrong order, -10 s"), "Spieler 2: falsche Reihenfolge, -10 s", "template with parts")
	assert_eq(_german().translate("Player 1: the bathroom is too dark"), "Spieler 1: das Bad ist zu dunkel", "generic error message")


func test_parts_can_change_their_order() -> void:
	assert_eq(_german().translate("Anna took the key"), "the key nahm Anna", "%2$s and %1$s")


func test_every_translation_keeps_its_placeholders() -> void:
	var placeholder := RegEx.create_from_string("%(?:\\d\\$)?[-+ 0-9.]*[sdfx]")
	for code in Lang.CATALOGS:
		var texts: Dictionary = load(Lang.CATALOGS[code]).TEXTS
		for english in texts:
			var wanted := placeholder.search_all(english).size()
			var got := placeholder.search_all(texts[english]).size()
			assert_eq(got, wanted, "%s: placeholders in %s" % [code, english])


func test_labels_switch_language_and_back() -> void:
	OS.set_environment("MERRY_SCARY_LANGUAGE_FILE", "user://test_language.cfg")
	DirAccess.remove_absolute("user://test_language.cfg")
	Lang.setup()
	assert_eq(Lang.current(), "en", "English the first time")
	var label := Label.new()
	label.text = "Player 3"
	tree.root.add_child(label)
	Lang.set_language("de")
	await wait_frames(1)
	assert_eq(label.get("text"), "Player 3", "the text itself stays English")
	assert_eq(tree.root.tr("Player 3"), "Spieler 3", "shown in German")
	assert_eq(Lang.saved_language(), "de", "remembered")
	Lang.set_language("pt")
	assert_eq(tree.root.tr("Player 3"), "Jogador 3", "Portuguese")
	Lang.set_language("en")
	assert_eq(tree.root.tr("Player 3"), "Player 3", "English again")
	DirAccess.remove_absolute("user://test_language.cfg")


func test_the_picker_on_the_title_switches_the_language() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	var device := Node.new()
	tree.root.add_child(device)
	tree.set_multiplayer(SceneMultiplayer.new(), device.get_path())
	device.add_child(main)
	main.warning_done = true  # the flashing warning comes first (spec 34)
	main.story_done = true
	main._update_screen()
	var picker: Control = main.find_child("LanguagePicker", true, false)
	assert_true(picker != null and picker.is_visible_in_tree(), "the picker on the title")
	for code in ["en", "de", "pt"]:
		assert_true(main.find_child("Language_" + code, true, false) != null, "a button for " + code)
	press(main, "Language_de")
	assert_eq(Lang.current(), "de", "German after a click")
	assert_eq(main.tr("Start"), "Start", "the title's button")
	assert_eq(main.tr("Player %d: %s" % [2, "wrong order, -10 s"]).begins_with("Spieler 2"), true, "messages in German")
	press(main, "Language_en")
	assert_eq(Lang.current(), "en", "back to English")
	main.title_done = true
	main._update_screen()
	assert_eq(picker.visible, false, "only on the title")


# The results card (merged from godot-setup) has several lines in one label: each one is
# translated by itself.
func test_the_results_card_is_translated_line_by_line() -> void:
	OS.set_environment("MERRY_SCARY_LANGUAGE_FILE", "user://test_language.cfg")
	Lang.setup()
	Lang.set_language("de")
	var ending: Node = load("res://scenes/ending.tscn").instantiate()
	ending.place = "scary"
	tree.root.add_child(ending)
	var rows: String = tree.root.tr(text_of(ending, "ResultsRows"))
	Lang.set_language("en")
	ending.queue_free()
	DirAccess.remove_absolute("user://test_language.cfg")
	assert_contains(rows, "Zeit übrig: ", "time left in German: %s" % rows)
	assert_contains(rows, "Fehler: keine", "no mistakes in German")
	assert_contains(rows, "Kräfte: keine", "no powers in German")
	assert_true(not rows.contains("Time left"), "no English line left")


func test_the_flashing_switch_is_translated() -> void:
	var de := Lang.TemplateTranslation.from_catalog("de", load(Lang.CATALOGS["de"]).TEXTS)
	assert_eq(de.translate("Reduce flashing: On"), "Weniger Flackern: An", "German")
	var pt := Lang.TemplateTranslation.from_catalog("pt", load(Lang.CATALOGS["pt"]).TEXTS)
	assert_eq(pt.translate("Reduce flashing: Off"), "Reduzir intermitência: Desligado", "Portuguese")


# ---------- spec 34: the texts fit in every language ----------

func _use_language(code: String) -> void:
	OS.set_environment("MERRY_SCARY_LANGUAGE_FILE", "user://test_language.cfg")
	Lang.setup()
	Lang.set_language(code)


func _back_to_english() -> void:
	Lang.set_language("en")
	DirAccess.remove_absolute("user://test_language.cfg")


# How wide a text is when it is written with this label's or button's letters.
func _text_width(control: Control, text: String) -> float:
	return control.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			control.get_theme_font_size("font_size")).x


# A word wider than its button would break in the middle ("Badezimm er").
func test_no_word_in_the_hall_breaks_in_the_middle() -> void:
	for code in ["en", "de", "pt"]:
		_use_language(code)
		var hall: Control = load("res://scenes/hall.tscn").instantiate()
		tree.root.add_child(hall)
		await wait_frames(2)
		for spot in ["FuseBoxButton", "Door_living_room", "Door_bathroom", "StairsButton", "Door_bedroom", "HousePlanButton"]:
			var button: Button = find(hall, spot)
			var room: float = button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x
			for word in tree.root.tr(button.text).replace("\n", " ").split(" ", false):
				assert_true(_text_width(button, word) <= room, "%s: '%s' needs %d, %s has %d" % [code, word, _text_width(button, word), spot, room])
		hall.queue_free()
		await wait_frames(1)
	_back_to_english()


func test_the_heroes_names_and_powers_fit() -> void:
	for code in ["en", "de", "pt"]:
		_use_language(code)
		var screen: Control = load("res://scenes/character_select.tscn").instantiate()
		tree.root.add_child(screen)
		for info in load("res://scripts/settings.gd").CHARACTERS:
			press(screen, "Card_" + info["id"])
			await wait_frames(2)
			var card: Control = find(screen, "Card_" + info["id"])
			var texts: Control = find(screen, "Power_" + info["id"]).get_parent()
			assert_true(texts.get_global_rect().end.x <= card.get_global_rect().end.x, "%s: %s inside its card" % [code, info["name"]])
			var power: Label = find(screen, "PowerLabel")
			var width := _text_width(power, tree.root.tr(power.text))
			assert_true(width <= power.size.x and power.get_global_rect().end.x <= 1152.0,
				"%s: the power line of %s is on the screen (%d wide, ends at %d)" % [code, info["name"], width, power.get_global_rect().end.x])
		screen.queue_free()
		await wait_frames(1)
	_back_to_english()


func test_the_leaderboard_stays_on_the_screen() -> void:
	for code in ["en", "de", "pt"]:
		_use_language(code)
		for place in ["merry", "midnight"]:
			var ending: Control = load("res://scenes/ending.tscn").instantiate()
			ending.place = place
			tree.root.add_child(ending)
			await wait_frames(2)
			var panel: Control = find(ending, "LeaderboardPanel")
			assert_true(panel.position.x + panel.size.x <= 1140.0, "%s, %s: ends at %d" % [code, place, panel.position.x + panel.size.x])
			ending.queue_free()
			await wait_frames(1)
	_back_to_english()


# Godot crashed when it was closed: our translations are scripts, and they were still in
# the TranslationServer after Godot had put its scripts away.
func test_closing_the_game_takes_the_translations_out() -> void:
	var device := Node.new()
	tree.root.add_child(device)
	tree.set_multiplayer(SceneMultiplayer.new(), device.get_path())
	var main = load("res://scenes/main.tscn").instantiate()
	device.add_child(main)
	assert_true(TranslationServer.get_loaded_locales().has("de"), "loaded while the game runs")
	device.free()
	for code in Lang.CATALOGS:
		assert_eq(TranslationServer.get_loaded_locales().has(code), false, code + " is taken out")
	Lang.setup()
	assert_true(TranslationServer.get_loaded_locales().has("pt"), "and can be loaded again")
