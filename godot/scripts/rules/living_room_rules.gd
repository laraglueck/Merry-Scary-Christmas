extends RefCounted
const Settings = preload("res://scripts/settings.gd")


static func try_clock(
	room: Dictionary,
	hour: int,
	minute: int
) -> Dictionary:
	if hour < 1 or hour > 12 or minute < 1 or minute > 12:
		return {
			"correct": false,
			"penalty_seconds": 0,
			"error": "Clock positions must be between 1 and 12.",
		}
	if hour == minute:
		return {
			"correct": false,
			"penalty_seconds": 0,
			"error": "Clock hands must point to different positions.",
		}
	if room["solved"]:
		return {
			"correct": false,
			"penalty_seconds": 0,
			"error": "Clock is already solved.",
		}

	var correct: bool = (
		hour == room["hour"]
		and minute == room["minute"]
	)

	if correct:
		room["solved"] = true

	return {
		"correct": correct,
				"penalty_seconds": 0 if correct else Settings.LIVING_ROOM_PENALTY_SECONDS,
				
		"error": "",
	}


static func create_room(rng: RandomNumberGenerator) -> Dictionary:
	var hour := rng.randi_range(1, 12)
	var minute := rng.randi_range(1, 11)

	if minute >= hour:
		minute += 1

	return {
		"hour": hour,
		"minute": minute,
		"digit": rng.randi_range(1, 9),
		"solved": false,
		"gift_taken": false,
	}


static func take_gift(room: Dictionary) -> Dictionary:
	if not room["solved"]:
		return {
			"taken": false,
			"error": "Solve the clock first.",
		}

	if room["gift_taken"]:
		return {
			"taken": false,
			"error": "Gift already taken.",
		}

	room["gift_taken"] = true

	return {
		"taken": true,
		"error": "",
	}
	
static func rhyme_for(tap_order: Array) -> Array[String]:
	if tap_order.size() != 4:
		return []

	var warm_lines: Array[String] = [
		"First, warm as fire burning bright,",
		"Then, warm as hearths on Christmas night.",
		"Again, warm as a candle's glow,",
		"Last, warm as embers burning low.",
	]

	var cold_lines: Array[String] = [
		"First, cold as stars in winter light,",
		"Then, cold as snow on Christmas night.",
		"Again, cold as the winds that blow,",
		"Last, cold as ice beneath the snow.",
	]

	var lines: Array[String] = []

	for i in range(4):
		if typeof(tap_order[i]) != TYPE_STRING:
			return []
			

		if tap_order[i] == "hot":
			lines.append(warm_lines[i])
		elif tap_order[i] == "cold":
			lines.append(cold_lines[i])
		else:
			return []

	return lines
	
