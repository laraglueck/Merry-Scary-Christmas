# Tests for spec 03: the lobby screen. Clicks buttons like a player.
extends "res://tests/base_test.gd"

const LobbyScene = preload("res://scenes/lobby.tscn")
const RoomCode = preload("res://scripts/net/room_code.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const GameRules = preload("res://scripts/rules/game_rules.gd")


func open_lobby() -> Node:
	var lobby = LobbyScene.instantiate()
	tree.root.add_child(lobby)
	return lobby


func test_lobby_starts_waiting() -> void:
	var lobby := open_lobby()
	assert_contains(text_of(lobby, "StatusLabel"), "create a room or join one", "status")
	assert_eq(is_disabled(lobby, "CreateButton"), false, "create enabled")


func test_create_room_makes_you_player_1() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	assert_contains(text_of(lobby, "PlayersLabel"), "Player 1 (you)", "players")
	assert_eq(is_disabled(lobby, "CreateButton"), true, "create disabled")
	assert_eq(is_disabled(lobby, "JoinButton"), true, "join disabled")


func test_join_with_invalid_input_shows_error() -> void:
	var lobby := open_lobby()
	var field := find(lobby, "AddressField")
	if field != null:
		field.text = "hello!"
	press(lobby, "JoinButton")
	assert_contains(text_of(lobby, "StatusLabel"), "not a valid room code or address", "status")
	assert_eq(is_disabled(lobby, "JoinButton"), false, "join still possible")


func test_create_room_shows_room_code() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	var text := text_of(lobby, "RoomCodeLabel")
	assert_true(text.begins_with("Room code: "), "label: " + text)
	assert_true(RoomCode.is_valid_code(text.trim_prefix("Room code: ")), "valid code in: " + text)


# ---------- start button (spec 04) ----------

func open_lobby_with(net: Node) -> Node:
	var lobby = LobbyScene.instantiate()
	lobby.net = net
	tree.root.add_child(lobby)
	type_name(lobby, "Team Rudolph")  # a name is needed before starting
	return lobby


func type_name(lobby: Node, text: String) -> void:
	var field: LineEdit = lobby.find_child("NameField", true, false)
	if field != null:
		field.text = text
		field.text_changed.emit(text)


func test_start_button_hidden_before_hosting() -> void:
	var lobby := open_lobby()
	var start := find(lobby, "StartButton")
	assert_eq(start != null and start.visible, false, "hidden")


func test_start_button_for_host_needs_three_players() -> void:
	var host := make_device("Host")
	host.host_room(47531)
	var lobby := open_lobby_with(host)
	var start := find(lobby, "StartButton")
	if start == null:
		return
	assert_eq(start.visible, true, "visible for the host")
	assert_eq(start.disabled, true, "1 player: disabled")
	var a := make_device("A")
	a.join_room("127.0.0.1", 47531)
	var b := make_device("B")
	await wait_until(func(): return a.connected)
	b.join_room("127.0.0.1", 47531)
	await wait_until(func(): return host.players.size() == 3)
	assert_eq(start.disabled, false, "3 players: enabled")
	press(lobby, "StartButton")
	assert_eq(host.game.get("phase"), "select", "the characters are chosen first (spec 18)")


func test_start_button_hidden_for_players() -> void:
	var room: Array = await make_full_room(47532)
	var lobby := open_lobby_with(room[1])
	var start := find(lobby, "StartButton")
	assert_eq(start != null and start.visible, false, "hidden for Player 2")


# ---------- save and resume (spec 15) ----------

func save_a_game(penalty: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var game := GameRules.new_game(rng)
	game["penalty_seconds"] = penalty
	SaveGame.save(game, SaveGame.path())


func is_shown(screen: Node, node_name: String) -> bool:
	var node := screen.find_child(node_name, true, false)
	return node != null and node.is_visible_in_tree()


func test_resume_button_only_for_the_host_with_a_save() -> void:
	var room: Array = await make_full_room(47586)
	var host_lobby := open_lobby_with(room[0])
	assert_eq(is_shown(host_lobby, "ResumeButton"), false, "no save: no Resume")
	save_a_game(30)
	room[0].changed.emit()  # the lobby looks again
	assert_eq(is_shown(host_lobby, "ResumeButton"), true, "save: Resume for the host")
	var player_lobby := open_lobby_with(room[1])
	assert_eq(is_shown(player_lobby, "ResumeButton"), false, "never for Player 2")


func test_resume_button_continues_the_saved_game() -> void:
	save_a_game(30)
	var room: Array = await make_full_room(47587)
	var lobby := open_lobby_with(room[0])
	assert_eq(is_disabled(lobby, "ResumeButton"), false, "3 players: enabled")
	press(lobby, "ResumeButton")
	assert_eq(room[0].game.get("penalty_seconds"), 30, "the saved game runs")


func test_new_game_over_a_save_asks_first() -> void:
	save_a_game(30)
	var room: Array = await make_full_room(47588)
	var lobby := open_lobby_with(room[0])
	press(lobby, "StartButton")
	assert_eq(room[0].game, {}, "not started yet")
	assert_eq(is_shown(lobby, "ConfirmNewGame"), true, "asks first")
	assert_contains(text_of(lobby, "ConfirmNewGameLabel"), "saved game will be lost", "says why")
	tree.root.size = Vector2i(1152, 648)
	await wait_frames(2)
	var yes: Control = lobby.find_child("YesNewGameButton", true, false)
	if yes != null:
		assert_true(lobby.get_viewport().get_visible_rect().encloses(yes.get_global_rect()), "the answer buttons fit on the screen: %s" % yes.get_global_rect())
	press(lobby, "CancelNewGameButton")
	assert_eq(is_shown(lobby, "ConfirmNewGame"), false, "question gone")
	assert_eq(room[0].game, {}, "still nothing started")
	assert_eq(SaveGame.load_from(SaveGame.path()).get("penalty_seconds"), 30, "the save is kept")
	press(lobby, "StartButton")
	press(lobby, "YesNewGameButton")
	assert_eq(room[0].game.get("phase"), "select", "a new game begins with the character selection (spec 18)")
	assert_eq(SaveGame.load_from(SaveGame.path()).get("penalty_seconds"), 30, "the old save stays until the game really starts")


func test_new_game_without_a_save_starts_at_once() -> void:
	var room: Array = await make_full_room(47589)
	var lobby := open_lobby_with(room[0])
	press(lobby, "StartButton")
	assert_eq(room[0].game.get("phase"), "select", "selection begins without asking (spec 18)")




# ---------- tidy-up (spec 03c) ----------

func test_open_room_shows_only_the_big_code_not_the_status_line() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	assert_true(text_of(lobby, "RoomCodeLabel").begins_with("Room code: "), "the big code")
	assert_eq(is_shown(lobby, "StatusLabel"), false, "no status line repeating it")


func test_errors_still_show_in_the_status_line() -> void:
	var lobby := open_lobby()
	var field := find(lobby, "AddressField")
	if field != null:
		field.text = "hello!"
	press(lobby, "JoinButton")
	assert_eq(is_shown(lobby, "StatusLabel"), true, "the error is shown")


func test_no_counter_in_the_lobby() -> void:
	var lobby := open_lobby()
	press(lobby, "CreateButton")
	assert_true(lobby.find_child("CounterLabel", true, false) == null, "no counter")
	assert_true(lobby.find_child("AddButton", true, false) == null, "no +1")


func test_code_field_is_big_but_not_the_whole_width() -> void:
	tree.root.size = Vector2i(1152, 648)
	var lobby := open_lobby()
	await wait_frames(2)
	var field: Control = lobby.find_child("AddressField", true, false)
	if field != null:
		var r := field.get_global_rect()
		assert_true(r.size.x >= 300 and r.size.x <= 600, "width %d: wide enough, not the whole screen" % r.size.x)
		assert_true(r.size.y >= 48, "tall: %d" % r.size.y)
		assert_true(field.get_theme_font_size("font_size") >= 26, "big letters")
		var join: Control = lobby.find_child("JoinButton", true, false)
		if join != null:
			assert_true(absf(join.get_global_rect().position.y - r.position.y) < 4, "Join next to the field")


func test_join_button_has_its_own_colour() -> void:
	var lobby := open_lobby()
	var join: Button = lobby.find_child("JoinButton", true, false)
	var create: Button = lobby.find_child("CreateButton", true, false)
	if join != null and create != null:
		var join_style = join.get_theme_stylebox("normal")
		var create_style = create.get_theme_stylebox("normal")
		assert_true(join_style is StyleBoxFlat, "Join has its own style")
		if join_style is StyleBoxFlat:
			var colour: Color = join_style.bg_color
			assert_true(colour.g > colour.r + 0.1 and colour.g > colour.b + 0.1, "green: %s" % colour)
			assert_true(not (create_style is StyleBoxFlat and create_style.bg_color == colour), "not the same as Create room")


# ---------- after the manual test (spec 03c) ----------

func test_players_2_and_3_wait_for_player_1() -> void:
	var lone := open_lobby()
	assert_eq(is_shown(lone, "WaitLabel"), false, "not before joining")
	var room: Array = await make_full_room(47591)
	var player_lobby := open_lobby_with(room[2])
	assert_eq(is_shown(player_lobby, "WaitLabel"), true, "Player 3 waits")
	assert_contains(text_of(player_lobby, "WaitLabel"), "Waiting for Player 1 to start the game", "says for whom")
	var host_lobby := open_lobby_with(room[0])
	assert_eq(is_shown(host_lobby, "WaitLabel"), false, "the host does not wait")


func test_start_button_green_and_not_the_whole_width() -> void:
	tree.root.size = Vector2i(1152, 648)
	var host := make_device("Host")
	host.host_room(47592)
	var lobby := open_lobby_with(host)
	await wait_frames(2)
	var start: Button = lobby.find_child("StartButton", true, false)
	if start != null:
		var width := start.get_global_rect().size.x
		assert_true(width <= 576, "not the whole width: %d" % width)
		var style = start.get_theme_stylebox("normal")
		assert_true(style is StyleBoxFlat and style.bg_color.g > style.bg_color.r + 0.1, "green")


func test_everything_in_the_middle_with_more_room() -> void:
	tree.root.size = Vector2i(1152, 648)
	var host := make_device("Host")
	host.host_room(47593)
	var lobby := open_lobby_with(host)
	await wait_frames(2)
	var middle := Vector2(576, 324)
	for node_name in ["LobbyTitle", "CreateButton", "RoomCodeLabel", "PlayersLabel", "StartButton"]:
		var node: Control = lobby.find_child(node_name, true, false)
		assert_true(node != null, node_name + " exists")
		if node != null:
			assert_true(absf(node.get_global_rect().get_center().x - middle.x) < 20, "%s in the middle: %s" % [node_name, node.get_global_rect()])
			if node is Label:
				assert_eq(node.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, node_name + " text centred")
	var field: Control = lobby.find_child("AddressField", true, false)
	var join: Control = lobby.find_child("JoinButton", true, false)
	var create: Control = lobby.find_child("CreateButton", true, false)
	var title: Control = lobby.find_child("LobbyTitle", true, false)
	var start: Control = lobby.find_child("StartButton", true, false)
	if field != null and join != null:
		var row_middle := (field.get_global_rect().position.x + join.get_global_rect().end.x) / 2
		assert_true(absf(row_middle - middle.x) < 20, "code field and Join in the middle")
	if title != null and start != null:
		var block_middle := (title.get_global_rect().position.y + start.get_global_rect().end.y) / 2
		assert_true(absf(block_middle - middle.y) < 40, "the block in the middle from top to bottom: %d" % block_middle)
	if create != null and field != null:
		var gap := field.get_global_rect().position.y - create.get_global_rect().end.y
		assert_true(gap >= 24, "more room between the lines: %d" % gap)




# ---------- name and single player (second test round) ----------

func test_a_name_is_needed_before_starting() -> void:
	var lobby := open_lobby()
	press(lobby, "PlayAloneButton")
	assert_eq(is_disabled(lobby, "StartButton"), true, "no name yet")
	assert_contains(text_of(lobby, "StartButton"), "name", "says why")
	type_name(lobby, "Gloria")
	assert_eq(is_disabled(lobby, "StartButton"), false, "with a name it starts")
	press(lobby, "StartButton")
	assert_eq(lobby.net.game.get("phase"), "select", "one player chooses a hero")
	assert_eq(lobby.net.team_name, "Gloria", "the name is kept")


func test_resume_says_when_the_save_is_for_three_players() -> void:
	save_a_game(30)  # saved with three players
	var lobby := open_lobby()
	press(lobby, "PlayAloneButton")
	assert_eq(is_disabled(lobby, "ResumeButton"), true, "cannot resume alone")
	assert_contains(text_of(lobby, "ResumeButton"), "3 players", "says why")


func test_play_alone_needs_no_room() -> void:
	var lobby := open_lobby()
	press(lobby, "PlayAloneButton")
	assert_eq(is_disabled(lobby, "CreateButton"), true, "no room needed")
	var alone: Control = lobby.find_child("PlayAloneButton", true, false)
	assert_eq(alone.visible, false, "once is enough")
	assert_contains(text_of(lobby, "PlayersLabel"), "alone", "says it")
