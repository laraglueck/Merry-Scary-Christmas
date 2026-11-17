# Spec 16: Attic and endings

Owner: Gloria (rules, screens and pictures)

## Why
The attic is the finale (Story and Rooms doc, "Attic" and "Endings"). The three digits from
the rooms open the attic lock. Beside the sleeping Scary Jingles the team decides: lock him
in (Scary Christmas) or leave the photo and cookies (Merry Christmas, only with the photo).
Midnight is the only loss and already exists (spec 13). This spec adds the lock, the
choice and one end screen for all three endings.
Rules first, then the screens, like the bathroom (spec 10).

## What

### Rules: `godot/scripts/rules/attic_rules.gd`
Pure GDScript, no scenes, no network. First check, then change; a refused action changes
nothing and comes back as an error text.

- `create()` returns the attic part of the shared game:

      {"unlocked": false, "choice": ""}

- `code(game)` returns the three digits the lock wants, in dial order red, green, gold:
  `game["living_room"]["digit"]`, `game["bathroom"]["digit"]`, `game["bedroom"]["digit"]`.
  Until Mika's bedroom exists (`game` has no `"bedroom"`), the gold digit is `0`, which
  means "not checked yet": any digit on the gold dial counts.
- `try_code(attic, dials, code)` returns `{correct, penalty_seconds, error}`:
  - right digits: `unlocked` becomes true, `{correct: true, penalty_seconds: 0, error: ""}`
  - wrong digits: nothing changes, `{correct: false, penalty_seconds: 20, error: ""}`
  - refused, nothing changes, an error text: not exactly three dials; a dial that is not a
    whole number from 1 to 9; already unlocked.
- `choose(attic, choice, has_photo)` returns `{ending, error}`:
  - `"lock_in"`: `choice` becomes `"lock_in"`, `ending` is `"scary"`.
  - `"reconcile"` with the photo: `choice` becomes `"reconcile"`, `ending` is `"merry"`.
  - refused, nothing changes, `ending` is `""`: the lock is still closed; an unknown choice;
    a choice was already made; `"reconcile"` without the photo, with the error
    "You have nothing that could change his mind."
- The penalty (20) goes into `settings.gd` as `ATTIC_PENALTY_SECONDS`.

### Shared game (small change, announce in the chat first)
- `game_rules.gd`: `"attic": AtticRules.create()` in `new_game()`; two actions in `apply()`,
  both only while the team is in the attic (`location == "attic"`), otherwise
  "Player 1: climb up to the attic first":
  - `try_attic_code` with `{"dials": [3, 7, 5]}`: right: "Player 1: the attic lock clicks
    open."; wrong: the penalty is added, "Player 1: wrong code, -20 s".
  - `choose_ending` with `{"choice": "lock_in"}` or `"reconcile"`: on success the phase
    becomes the ending (`"scary"` or `"merry"`), so the game stops like at midnight.
    `"lock_in"` also puts the key into the inventory. Events: "Player 1 took the key and
    locked Scary Jingles in." / "Player 1 left the photo and the cookies beside him."
- `settings.gd`: the photo item gets the new picture `item_photo.png`.

### Attic screen: `godot/scenes/attic.tscn` + `godot/scripts/attic.gd`
Built like the bathroom: the screen shows the state and reacts to keys and clicks; the
rules decide.

- Before the lock is open: a close-up of the attic door lock with three dials in red,
  green and gold. Clicking a dial (or `↑` `↓` on the highlighted dial, `←` `→` to change
  dial) turns it through 1 to 9; a Try button (or Enter) sends the code. Back to the hall.
- After the lock is open: `room_attic.webp` with Scary Jingles asleep in his armchair
  (`char_jingles_asleep.png`) on the left, facing into the room, the key on the floor beside
  him, and two choices:
  - "Lock him in"
  - "Leave the photo and cookies": greyed out without the photo, with the reason shown
    when it is clicked.
- Message line at the bottom, from the shared game's `last_event`.
- Online / offline like the bathroom: online every action goes to the host through
  `net.send_action`; offline (Cmd R) the screen keeps its own game, already in the attic,
  and `seed_value` fixes it for tests. An offline `has_photo` switch lets us try the Merry
  ending before the bedroom exists.

### End screen: `godot/scenes/ending.tscn` + `godot/scripts/ending.gd`
One screen for the three phases that end the game:

| Phase | Picture | Title | Line |
| --- | --- | --- | --- |
| `merry` | `ui_win_merry.webp` | Merry Christmas! | Scary Jingles remembered who he was. |
| `scary` | `ui_win_scary.webp` | Scary Christmas! | Scary Jingles is locked in. The presents are safe. |
| `midnight` | `ui_lose.webp` | Midnight | The clock struck twelve. Scary Jingles has won. |

- Under the line: the presents found (from the inventory) and, for the two wins, the time
  that was left.
- A "Back to the lobby" button, where the host can start a new game.

### Main screen (one line each, announce to Mathies)
- `main.gd`: `"attic"` → `attic.tscn`; `"merry"`, `"scary"`, `"midnight"` → `ending.tscn`.

## Out of scope
The walk back to the garden and the front door (the hall has no front door yet, so "Lock
him in" ends the game in the attic), the floorboards, roles, noise and wind, Scary Jingles
waking up (`char_jingles_awake.png` waits for that), the bedroom's real digit and photo
(Mika), sounds (Leon).

## Done when
- `godot/tests/test_attic_rules.gd`, `test_attic_game.gd`, `test_attic.gd` and
  `test_ending.gd` were red first and are green; all older tests stay green.
  - Rules: the code is the three room digits; without a bedroom the gold dial is not
    checked; the right code opens the lock; a wrong code gives 20 s and changes nothing
    else; two or four dials, a dial outside 1 to 9 or not a whole number, or trying when
    open are refused; a choice before the lock is open, an unknown choice, a second choice
    and "reconcile" without the photo are refused and change nothing; "lock_in" gives
    "scary", "reconcile" with the photo gives "merry".
  - Game: the actions work through `GameRules.apply`, only in the attic; a wrong code adds
    20 s; the choice sets the phase; "lock_in" puts the key into the inventory; after the
    ending, nothing changes any more.
  - Attic screen: the dials turn and wrap from 9 to 1; the right code shows Scary Jingles
    and the choices; the photo choice is greyed out without the photo.
  - End screen: each phase shows its title and picture.
- All tests green with `godot --headless --path godot --script res://tests/run_tests.gd`.
- Manual: Cmd R on `attic.tscn`, open the lock and choose, with the keyboard only, then
  with the mouse only.
