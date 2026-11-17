# Spec 10: Bathroom

Owner: Gloria (rules, screen and pictures)

## Why
The bathroom is the room behind the green fuse. Its lock is a pair of taps: players turn
them four times in the order the rhyme in the living room gives. When the order is right,
steam shows three symbols in the mirror (the clue for the bedroom chest) and the tub
drains: present 2 and a digit for the green dial of the attic lock.
Rules first, then the screen, like the fuse puzzle (specs 01 and 02).

## What

### Rules: `godot/scripts/rules/bathroom_rules.gd`
Pure GDScript, no scenes, no network. First check, then change; a refused action changes
nothing and comes back as an error text.

- `create(rng)` returns the bathroom part of the shared game:

      {"tap_order": ["hot", "cold", "cold", "hot"], "digit": 7,
       "solved": false, "gift_taken": false}

  `tap_order` is four random turns, each `"hot"` or `"cold"`; `digit` is 1 to 9.
  Same rng seed, same bathroom.
- `try_taps(room, taps)` returns `{correct, penalty_seconds, error}`:
  - right order: `solved` becomes true, `{correct: true, penalty_seconds: 0, error: ""}`
  - wrong order: nothing changes, `{correct: false, penalty_seconds: 20, error: ""}`
  - refused, nothing changes, an error text: not exactly four turns; a turn that is not
    `"hot"` or `"cold"`; already solved.
- `take_gift(room)` returns `{ok, error}`: refused before solving and the second time;
  otherwise `gift_taken` becomes true.
- `mirror_symbols(wheels)` returns the bedroom's three symbols in reverse order
  (the mirror image). Until Mika's bedroom exists, the screen uses an example.
- The penalty (20) and the words `"hot"`, `"cold"` go into `settings.gd`.

### Screen: `godot/scenes/bathroom.tscn` + `godot/scripts/bathroom.gd`
Built like the hall: the screen shows the state and reacts to keys and clicks; the rules
decide.

- Background: `room_bathroom_dark.webp` while the green fuse is off,
  `room_bathroom_lit.webp` when it is on (green = fuse 1 in `puzzle.fuses`).
- Five spots, each a clickable area over the picture with a name label; positions in one
  constant at the top of `bathroom.gd`, to adjust when the real picture arrives:
  `hot_tap`, `cold_tap`, `mirror`, `bathtub`, `door_hall`.
- Keys (Godot's built-in `ui_*` actions, so no shared file changes): `←` `→` move a
  highlight from spot to spot; `↑` or Enter uses the highlighted spot; `Esc` or `↓`
  closes a close-up. A mouse click on a spot does the same. The highlight stands in for
  the walking hero until spec 07 exists.
- Taps: each use of `hot_tap` or `cold_tap` adds that turn; four small marks under the
  sink show the turns so far (red = hot, blue = cold). After the fourth turn the order is
  tried. Moving the highlight away from the taps clears unfinished turns.
- Mirror close-up: before solving, dust; after solving, steam over the glass and the
  three symbols from `mirror_symbols`, each flipped left-right (pictures `sym_*.png`).
- Bathtub: before solving, dark water; after, the empty tub with present 2
  (`item_gift_2.png`) and the digit. Using `bathtub` then takes the present once.
- Message line at the bottom of the screen:

  | When | Text |
  | --- | --- |
  | Right order | The pipes rattle. The water drains away. |
  | Wrong order | The pipes rattle angrily. -20 s |
  | A tap after solving | The taps are dry. |
  | Mirror before solving | Too much dust to see anything. |
  | Taking the present | You found the second present! |

- Online (main.gd hands in `net` with a game): turns go to the host as action
  `turn_taps` with `{"taps": [4 turns]}`, the present as `take_gift` with
  `{"room": "bathroom"}`; everything shown comes from `net.game`.
  Offline (no network, open with Cmd R): the screen keeps its own bathroom from
  `bathroom_rules.create`, with the green fuse on, and calls the rules directly.
  `seed_value` fixes it for tests.

### Shared game (small change, announce in the chat first)
- `game_rules.gd`: `"bathroom": BathroomRules.create(rng)` in `new_game()`; actions
  `turn_taps` and `take_gift` (room `"bathroom"`) in `apply()`, with events in
  `last_event` and the penalty added to `penalty_seconds`.

## Out of scope
Walking and entering the room from the hall (Mathies, spec 07), the bedroom's real wheels
(Mika), real artwork (placeholders are fine), sounds (Leon), the mirror jumpscare,
easter eggs, the clock.

## Done when
- `godot/tests/test_bathroom_rules.gd` and `godot/tests/test_bathroom.gd` were red first
  and are green; all older tests stay green.
  - Rules: the same seed gives the same bathroom; every turn is hot or cold and the digit
    1 to 9; the right order solves it; a wrong order gives 20 s and changes nothing else;
    three or five turns, an unknown turn, or trying when solved are refused and change
    nothing; the present is refused before solving and the second time;
    `mirror_symbols` reverses the three symbols.
  - Screen: the arrows move the highlight; four right turns solve it; a wrong order clears
    the marks and shows the message; the mirror shows nothing before solving and the
    symbols after; the present can be taken only after solving and only once; the dark
    picture shows while the green fuse is off.
  - Game: `turn_taps` and `take_gift` work through `GameRules.apply`.
- All tests green with `godot --headless --path godot --script res://tests/run_tests.gd`.
- Manual: Cmd R on `bathroom.tscn`, solve it with the keyboard only, then with the mouse only.
