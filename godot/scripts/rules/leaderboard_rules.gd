# Leaderboard and Christmas countdown (second test round). Pure functions: no screens,
# no network, no files. The leaderboard keeps the fastest wins: team (or player) name,
# ending and the time left before midnight. Rows from outside are checked before use.
extends RefCounted

const Settings = preload("res://scripts/settings.gd")
const ClockRules = preload("res://scripts/rules/clock_rules.gd")

const TOP := 10
const ENDINGS := ["merry", "scary"]
const NO_NAME := "Nameless heroes"


# The leaderboard row for a finished game, or {} when it is not a win.
static func entry_for(game: Dictionary) -> Dictionary:
	var ending := str(game.get("phase", ""))
	if ending not in ENDINGS:
		return {}
	var name := str(game.get("team_name", "")).strip_edges().left(Settings.NAME_LENGTH)
	return {"name": name if name != "" else NO_NAME, "ending": ending,
		"seconds_left": ClockRules.time_left(game)}


# Is this a row we accept (from our own game or from the online list)?
static func is_valid(row) -> bool:
	if not row is Dictionary:
		return false
	var name := str(row.get("name", "")).strip_edges()
	var seconds = row.get("seconds_left", -1)
	return name != "" and name.length() <= Settings.NAME_LENGTH \
		and str(row.get("ending", "")) in ENDINGS \
		and (seconds is int or seconds is float) and seconds >= 0 and seconds <= 3600


# The best TOP rows: most time left first.
static func top(rows: Array) -> Array:
	var good := rows.filter(is_valid)
	good.sort_custom(func(a, b): return int(a["seconds_left"]) > int(b["seconds_left"]))
	return good.slice(0, TOP)


# Rows from a saved file or the online list (JSON text). Anything broken: an empty list.
static func rows_from_text(text: String) -> Array:
	var json := JSON.new()  # quietly: a broken answer is no error, just an empty list
	if json.parse(text) != OK or not json.data is Array:
		return []
	var data: Array = json.data
	var rows := []
	for row in data:
		if is_valid(row):
			rows.append({"name": str(row["name"]).strip_edges(), "ending": str(row["ending"]),
				"seconds_left": int(row["seconds_left"])})
	return rows


# Days from the given date ({"year", "month", "day"}) until Christmas Eve, 24 December.
static func days_until_christmas(date: Dictionary) -> int:
	var today := Time.get_unix_time_from_datetime_dict({"year": date["year"], "month": date["month"], "day": date["day"]})
	var eve_year: int = date["year"]
	if date["month"] == 12 and date["day"] > 24:
		eve_year += 1
	var eve := Time.get_unix_time_from_datetime_dict({"year": eve_year, "month": 12, "day": 24})
	return int(round((eve - today) / 86400.0))


static func countdown_text(days: int) -> String:
	if days == 0:
		return "Christmas Eve is tonight!"
	return "Only %d %s until Christmas Eve!" % [days, "day " if days == 1 else "days"]
