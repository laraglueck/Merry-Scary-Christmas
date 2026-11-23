# Languages (spec 34): English, German, Portuguese.
#
# The game is written in English, and English stays the source: every text in the code, in
# the rules and in the tests is English. On the screen Godot translates every Label, Button,
# tooltip and placeholder by itself ("auto translate") through TemplateTranslation below.
#
# The rules build messages like "Player 2: wrong order, -10 s" on the host, in English.
# Each device translates them for itself, in its own language: a text with a number or a
# name in it matches a template like "%s: wrong order, -%d s", and the parts are translated
# one by one ("Player 2" -> "Spieler 2"). So three players can each play in their own language.
#
# The texts are in scripts/translations/de.gd and pt.gd (English text -> translation).
extends RefCounted

const LANGUAGES := [
	{"code": "en", "name": "English"},
	{"code": "de", "name": "Deutsch"},
	{"code": "pt", "name": "Português"},
]
const CATALOGS := {
	"de": "res://scripts/translations/de.gd",
	"pt": "res://scripts/translations/pt.gd",
}
const DEFAULT_FILE := "user://language.cfg"


# Once per start (main.gd): the translations, then the language chosen last time
# (English the first time).
static func setup() -> void:
	for code in CATALOGS:
		if not TranslationServer.get_loaded_locales().has(code):
			TranslationServer.add_translation(TemplateTranslation.from_catalog(code, load(CATALOGS[code]).TEXTS))
	TranslationServer.set_locale(saved_language())


static func current() -> String:
	var locale := TranslationServer.get_locale().substr(0, 2)
	return locale if CATALOGS.has(locale) else "en"


# Switches every screen at once (auto translate) and remembers it for the next start.
static func set_language(code: String) -> void:
	if code != "en" and not CATALOGS.has(code):
		return
	TranslationServer.set_locale(code)
	var file := FileAccess.open(_file_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(code)


static func saved_language() -> String:
	if not FileAccess.file_exists(_file_path()):
		return "en"
	var code := FileAccess.get_file_as_string(_file_path()).strip_edges()
	return code if CATALOGS.has(code) else "en"


# The tests set MERRY_SCARY_LANGUAGE_FILE, so they never change the real choice.
static func _file_path() -> String:
	var for_tests := OS.get_environment("MERRY_SCARY_LANGUAGE_FILE")
	return for_tests if for_tests != "" else DEFAULT_FILE


# One language: exact texts first, then templates with %s / %d for texts with names and numbers.
class TemplateTranslation extends Translation:
	const PLACEHOLDER := "%(?:(\\d)\\$)?[-+ 0-9.]*[sdfx]"
	var texts := {}       # English -> translation
	var templates := []   # {"regex": RegEx, "target": String}, the most specific first

	static func from_catalog(code: String, catalog: Dictionary) -> TemplateTranslation:
		var translation := TemplateTranslation.new()
		translation.locale = code
		var placeholder := RegEx.create_from_string(PLACEHOLDER)
		for english in catalog:
			var target: String = catalog[english]
			if target == "":
				continue
			translation.texts[english] = target
			if placeholder.search(english) == null:
				continue
			var literal := placeholder.sub(english, "", true)
			if literal.strip_edges() == "":
				continue  # "%s" alone would match everything
			translation.templates.append({"regex": RegEx.create_from_string(_pattern(english, placeholder)),
				"target": target, "weight": literal.length()})
		translation.templates.sort_custom(func(a, b): return a["weight"] > b["weight"])
		return translation

	# "%s: wrong order, -%d s" -> ^(.+?): wrong order, -(-?\d+) s$
	static func _pattern(english: String, placeholder: RegEx) -> String:
		var pattern := "^"
		var at := 0
		for found in placeholder.search_all(english):
			pattern += _escape(english.substr(at, found.get_start() - at))
			pattern += "(-?\\d+)" if found.get_string().ends_with("d") else "(.+?)"
			at = found.get_end()
		return pattern + _escape(english.substr(at)) + "$"

	static func _escape(text: String) -> String:
		var out := ""
		for c in text:
			out += ("\\" + c) if c in "\\^$.|?*+()[]{}" else c
		return out

	func _get_message(src_message: StringName, _context: StringName) -> StringName:
		return StringName(translate(String(src_message)))

	func translate(text: String, depth := 0) -> String:
		if text == "":
			return text
		if texts.has(text):
			return texts[text]
		if depth > 3:
			return text
		for template in templates:
			var found: RegExMatch = template["regex"].search(text)
			if found == null:
				continue
			var parts: Array[String] = []
			for i in range(1, found.get_group_count() + 1):
				parts.append(translate(found.get_string(i), depth + 1))
			return _fill(template["target"], parts)
		return text

	# Puts the parts into the translation, in order, or by number: "%2$s" is the second part.
	static func _fill(target: String, parts: Array[String]) -> String:
		var placeholder := RegEx.create_from_string(PLACEHOLDER)
		var out := ""
		var at := 0
		var next := 0
		for found in placeholder.search_all(target):
			out += target.substr(at, found.get_start() - at)
			var index := next
			if found.get_string(1) != "":
				index = int(found.get_string(1)) - 1
			else:
				next += 1
			out += parts[index] if index < parts.size() else ""
			at = found.get_end()
		return out + target.substr(at)
