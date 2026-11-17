extends RefCounted


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
		"penalty_seconds": 0 if correct else 20,
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
	
