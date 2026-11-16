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


# ---------- helpers for screens: find nodes, press buttons ----------

func find(screen: Node, node_name: String) -> Node:
	var node := screen.find_child(node_name, true, false)
	if node == null:
		failures.append("node not found: " + node_name)
	return node


func press(screen: Node, node_name: String) -> void:
	var button := find(screen, node_name)
	if button != null:
		button.pressed.emit()


func text_of(screen: Node, node_name: String) -> String:
	var node := find(screen, node_name)
	return node.text if node != null else ""


func is_disabled(screen: Node, node_name: String) -> bool:
	var button := find(screen, node_name)
	return button != null and button.disabled
