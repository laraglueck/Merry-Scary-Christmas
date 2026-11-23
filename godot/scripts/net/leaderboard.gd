# The leaderboard's storage (second test round): where the fastest wins are kept.
# - Online, when Supabase is set up: a shared table everyone sees, read and written over
#   Supabase's REST interface with the project's public "anon" key. The table itself only
#   accepts sensible rows (see README: name 1-20 letters, merry/scary, 0-3600 s).
# - Otherwise, and whenever the internet does not answer in time: a file on this computer.
# The address and key are NOT in the repository: they come from the environment variables
# SUPABASE_URL and SUPABASE_ANON_KEY, or from user://supabase.cfg ([supabase] url=..., key=...).
extends Node

const Rules = preload("res://scripts/rules/leaderboard_rules.gd")

const TIMEOUT_SECONDS := 4.0
const TABLE := "leaderboard"

signal updated(rows: Array)  # the best rows, after loading or saving

var rows: Array = []
var online := false   # true when Supabase is set up
var _url := ""
var _key := ""


func _ready() -> void:
	_read_config()


# The local file; tests use their own (MERRY_SCARY_LEADERBOARD).
static func local_path() -> String:
	var for_tests := OS.get_environment("MERRY_SCARY_LEADERBOARD")
	return for_tests if for_tests != "" else "user://leaderboard.json"


func _read_config() -> void:
	_url = OS.get_environment("SUPABASE_URL")
	_key = OS.get_environment("SUPABASE_ANON_KEY")
	if _url == "" or _key == "":
		var config := ConfigFile.new()
		if config.load("user://supabase.cfg") == OK:
			_url = str(config.get_value("supabase", "url", ""))
			_key = str(config.get_value("supabase", "key", ""))
	online = _url != "" and _key != "" and OS.get_environment("MERRY_SCARY_LEADERBOARD") == ""


# Loads the best rows: online if possible, else (or on failure) the local file.
func load_top() -> void:
	if online:
		_request(HTTPClient.METHOD_GET,
			"%s/rest/v1/%s?select=name,ending,seconds_left&order=seconds_left.desc&limit=%d" % [_url, TABLE, Rules.TOP], "")
	else:
		_show(_read_local())


# Saves one win (always locally, and online when set up), then shows the list.
func submit(entry: Dictionary) -> void:
	if not Rules.is_valid(entry):
		load_top()
		return
	var local := _read_local()
	local.append(entry)
	_write_local(local)
	if online:
		_request(HTTPClient.METHOD_POST, "%s/rest/v1/%s" % [_url, TABLE], JSON.stringify(entry), true)
	else:
		_show(local)


func _show(all_rows: Array) -> void:
	rows = Rules.top(all_rows)
	updated.emit(rows)


func _read_local() -> Array:
	if not FileAccess.file_exists(local_path()):
		return []
	return Rules.rows_from_text(FileAccess.get_file_as_string(local_path()))


func _write_local(all_rows: Array) -> void:
	var file := FileAccess.open(local_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(Rules.top(all_rows) if all_rows.size() > 50 else all_rows))


# One request to Supabase. Whatever goes wrong (no internet, slow, refused), the local
# list is shown instead, so the end screen never waits or breaks.
func _request(method: int, url: String, body: String, then_load := false) -> void:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers, data: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code >= 300:
			_show(_read_local())
		elif then_load:
			load_top()
		else:
			_show(Rules.rows_from_text(data.get_string_from_utf8())))
	var headers := ["apikey: " + _key, "Authorization: Bearer " + _key, "Content-Type: application/json",
		"Prefer: return=minimal"]
	if http.request(url, headers, method, body) != OK:
		http.queue_free()
		_show(_read_local())
