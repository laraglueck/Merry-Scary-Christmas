# Base class for our tests: every test file extends this and can use these checks.
extends RefCounted

var failures: Array[String] = []
var tree: SceneTree  # set by run_tests.gd, needed to open scenes


func assert_eq(actual, expected, what := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s\n        expected: %s\n        actual:   %s" % [what, expected, actual])


func assert_true(condition: bool, what := "") -> void:
	if not condition:
		failures.append("%s: expected true" % what)


func assert_contains(text: String, part: String, what := "") -> void:
	if part.to_lower() not in text.to_lower():
		failures.append("%s: expected \"%s\" in \"%s\"" % [what, part, text])
