# Test runner: runs every file res://tests/test_*.gd and in it every function
# whose name starts with test_. A test fails if a check fails OR if Godot
# reports an error while it runs (so a crash can never look green).
# Start from the repo folder:
#   godot --headless --path godot --script res://tests/run_tests.gd
# Tests never touch the real save (spec 15): they use TEST_SAVE, deleted before every test.
extends SceneTree


class ErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text := rationale if rationale != "" else code
		errors.append("error: %s (%s:%d)" % [text, file.get_file(), line])

	func _log_message(message: String, error: bool) -> void:
		pass


const TEST_SAVE := "user://test_saved_game.save"

var _started := false


# Wait for the first frame: only then is the scene tree ready for scenes.
# _run_all may pause (await) inside a test; the loop keeps running meanwhile.
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false


func _run_all() -> void:
	OS.set_environment("MERRY_SCARY_SAVE", TEST_SAVE)
	# The leaderboard too: tests never touch the real list or the internet.
	OS.set_environment("MERRY_SCARY_LEADERBOARD", "user://test_leaderboard.json")
	# And the language (spec 34): the tests read the English texts, whatever was chosen last.
	OS.set_environment("MERRY_SCARY_LANGUAGE_FILE", "user://test_language.cfg")
	DirAccess.remove_absolute("user://test_language.cfg")
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var passed := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at("res://tests"))
	files.sort()
	for file_name in files:
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		print("\n" + file_name)
		catcher.errors.clear()
		var script: GDScript = load("res://tests/" + file_name)
		# A test file Godot can't read (e.g. it uses a name that doesn't exist yet)
		# must count as red, not be skipped silently.
		if script == null or not script.can_instantiate():
			failed += 1
			print("  FAIL  (could not load the file)")
			for problem in catcher.errors:
				print("        ", problem)
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			DirAccess.remove_absolute(TEST_SAVE)  # every test starts without a save
			var suite = script.new()
			suite.tree = self
			catcher.errors.clear()
			await suite.call(name)  # tests may wait for frames
			for child in root.get_children():
				child.free()
			var problems: Array[String] = []
			problems.append_array(suite.failures)
			problems.append_array(catcher.errors)
			if problems.is_empty():
				passed += 1
				print("  ok    ", name)
			else:
				failed += 1
				print("  FAIL  ", name)
				for problem in problems:
					print("        ", problem)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
