# Team guide: how the game is built and how to add your part

Short version: **one shared `game` Dictionary on the host, changed only by
`game_rules.gd`; screens show `net.game` and send actions.** Everything else follows.

## 1. Run the game

- Godot **4.7.2**. Open `godot/project.godot`.
- **▶** (Mac: ⌘ B) starts the main scene `scenes/main.tscn`.
- **3 players on one computer:** Debug > Customize Run Instances… > Enable Multiple
  Instances, 3 > OK, then ▶. Window 1: *Create room*. Windows 2 and 3: type the room
  code, *Join* (one after the other). Window 1: *Start game*.
- **Real devices:** same Wi-Fi, or a phone hotspot if the university Wi-Fi blocks it.
  If the code is not found, type the host's address shown in its status (plan B).
  macOS asks to allow incoming connections: *Allow*.
- **Mac keys:** ⌘ R runs the scene you have open (F6 is a Mac media key).
- A single screen still opens on its own, e.g. `scenes/hall.tscn` (⌘ R) with a player switch.

## 2. The big picture

```
  Player 2's device                        Host = Player 1 (the referee)
 +------------------+   send_action()     +-----------------------------+
 | screen (e.g.     | ------------------> | GameRules.apply(game, ...)  |
 | hall) shows      |                     | changes the `game` Dict     |
 | net.game         | <------------------ | and sends it to everyone    |
 +------------------+   new game          +-----------------------------+
```

- **`game`** is one Dictionary on the host. Only the host changes it, and only with
  the functions in `scripts/rules/game_rules.gd`. Then every player gets a copy.
- **Screens never change `game` themselves.** They show `net.game` and call
  `net.send_action("action_name", {data})`. They redraw on `net.game_changed`.
- **`main.gd`** keeps the network and shows the screen for `game["phase"]`
  (the lobby before the game starts or after the host left).
- Player numbers: index 0, 1, 2 = Player 1 (host), Player 2, Player 3.

## 3. Where things are (inside `godot/`)

| File | What it is |
|---|---|
| `scenes/main.tscn`, `scripts/main.gd` | Main scene: network + current screen (`SCREENS`) |
| `scripts/net/network.gd` | Rooms, players, the shared `game`, `send_action` |
| `scripts/net/room_code.gd` | 4-letter room codes and the Wi-Fi announcement |
| `scripts/rules/game_rules.gd` | **The shared game: `new_game()` and `apply()`** |
| `scripts/rules/fuse_rules.gd` | Fuse puzzle rules (pure functions) |
| `scripts/settings.gd` | All numbers and names (penalties, colours, port, ...) |
| `scenes/lobby.tscn`, `scenes/hall.tscn` | Screens |
| `tests/` | Tests (see section 6) |
| `../specs/` | One spec per feature: Why / What / Out of scope / Done when |

## 4. Add your part, step by step

Example: the bedroom's advent calendar ("Santa never opened one door").

1. **Spec** in `specs/` (Why / What / Out of scope / Done when).
2. **Rules + tests first:** pure functions in `scripts/rules/bedroom_rules.gd`, tests in
   `tests/test_bedroom_rules.gd` (copy the pattern of `test_fuse_rules.gd`).
   First check, then change. GDScript has no exceptions: return an error text instead.
3. **Data** in `GameRules.new_game()`:
   ```gdscript
   "bedroom": {"closed_door": rng.randi_range(1, 9), "solved": false},
   ```
4. **Action** in `GameRules.apply()`:
   ```gdscript
   match action:
       "try_fuse":
           _try_fuse(game, player, data)
       "open_door":
           BedroomRules.open_door(game, player, data.get("door", -1))
   ```
5. **Screen** `scenes/bedroom.tscn` + `scripts/bedroom.gd`:
   ```gdscript
   extends Control

   var net: Node = null  # main.gd hands this in before the screen starts

   func _ready() -> void:
       net.game_changed.connect(_refresh)
       # build buttons ..., then:
       _refresh()

   func _on_door_pressed(door: int) -> void:
       net.send_action("open_door", {"door": door})  # the host decides

   func _refresh() -> void:
       if net.game.is_empty():
           return  # game over, main.gd switches the screen
       var bedroom: Dictionary = net.game["bedroom"]
       # show it ...
   ```
6. **Show the screen:** add it to `SCREENS` in `main.gd`. Moving between rooms is not
   built yet, see section 5.
7. **Numbers** (penalties, counts) go into `settings.gd`.

## 5. Shared pieces not built yet (talk to us before you start)

- **Moving between rooms.** Players can be in different rooms. Proposal:
  `game["where"] = {0: "hall", 1: "bathroom", 2: "hall"}`, action `"go_to"`
  (only into lit rooms), and `main.gd` shows the screen for `where[my_index]`.
  Mathies can build this next.
- **Clock** (10 minutes): host counts down `game["time_left"]`, penalties subtract.
- **Attic code, win and lose.**
- **A player leaves during the game** (out of scope so far).

## 6. Tests

- Run all tests from the repo folder (Mac):
  ```
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/run_tests.gd
  ```
- A test file is `tests/test_<name>.gd`, starts with
  `extends "res://tests/base_test.gd"`, and every function named `test_...` is a test.
- Checks: `assert_eq`, `assert_true`, `assert_contains`. Screens: `find`, `press`,
  `text_of`, `is_disabled`. Network: `make_device`, `make_full_room`,
  `make_started_room`, `wait_until` (use `await`).
- **Red first:** write the test, see it fail for the right reason, then write the code.
- A Godot error while a test runs counts as a failure, so a crash can't look green.
- Network tests: give every test its own port (look at the numbers already used).

## 7. Git

- Branch from **`godot-setup`**, Pull Request into **`godot-setup`** (not `main`).
- Before a new branch and after every merge: `godot-setup`, Fetch, Pull.
- Work in your own files, then there are no conflicts. Shared files
  (`game_rules.gd`, `main.gd`, `settings.gd`, `project.godot`): small changes,
  say so in the group chat first.
- Commit the `.uid` files Godot creates. Never commit `.godot/` (it is ignored).

## 8. Pitfalls we already hit

- A Label with autowrap inside an `HBoxContainer` gets 1 px wide and breaks after
  every letter. Only wrap labels that have a fixed width.
- Constant arrays from `settings.gd` are read-only: `.duplicate()` before changing.
- Don't close the network inside a network message: use `call_deferred`.
- Two windows on one computer can't search for a room at the very same moment:
  join one after the other.
