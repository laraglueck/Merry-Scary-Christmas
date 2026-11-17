# Save and resume (spec 15): the shared game as a text file on the host's laptop.
# var_to_str / str_to_var keep the types (a whole number stays a whole number),
# so a saved game loads back exactly as it was.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")


# The save file. The tests set MERRY_SCARY_SAVE, so they never touch the real save.
static func path() -> String:
	var for_tests := OS.get_environment("MERRY_SCARY_SAVE")
	return for_tests if for_tests != "" else Settings.SAVE_PATH


static func save(game: Dictionary, file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the game to %s" % file_path)
		return
	file.store_string(var_to_str(game))


# The saved game, or {} when there is none or the file is broken.
static func load_from(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var loaded = str_to_var(FileAccess.get_file_as_string(file_path))
	if typeof(loaded) != TYPE_DICTIONARY:
		return {}
	return loaded


static func exists(file_path: String) -> bool:
	return not load_from(file_path).is_empty()


static func remove(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
