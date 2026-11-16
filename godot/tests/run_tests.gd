# Test runner: runs every file res://tests/test_*.gd and in it every function
# whose name starts with test_. A test fails if a check fails OR if Godot
# reports an error while it runs (so a crash can never look green).
# Start from the repo folder:
#   godot --headless --path godot --script res://tests/run_tests.gd
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


func _init() -> void:
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
		var script: GDScript = load("res://tests/" + file_name)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var suite = script.new()
			catcher.errors.clear()
			suite.call(name)
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
