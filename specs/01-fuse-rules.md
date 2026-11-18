# Spec 01: Fuse puzzle rules (Godot)

Owner: Mathies (hall + fuses)

## Why
The fuse puzzle is the heart of the demo. Its rules must work and be tested
before we draw the hall or connect players.

## What
A rules script `godot/scripts/rules/fuse_rules.gd` (pure GDScript, no scenes,
no network). The puzzle is a plain Dictionary, so it can later be sent to every player.

- `create_puzzle(rng)`: one legend per game (4 symbols -> 4 wire colours,
  shuffled) and 3 fuses (red -> living/dining room, green -> bathroom,
  gold -> bedroom), each with its own shuffled order of the 4 wire colours,
  all unsolved. Same rng seed -> same puzzle.
- `label_for(puzzle, fuse_index)`: that fuse's wire order written as symbols.
- `label_viewer(fuse_index)`: the player who sees the label, never the owner
  (fuse 0 -> player 1, fuse 1 -> player 2, fuse 2 -> player 0).
  Fuse i belongs to player i.
- `try_fuse(puzzle, fuse_index, wires)` returns a result Dictionary:
  - right order: fuse solved, `{correct: true, penalty_seconds: 0, error: ""}`
  - wrong order: nothing changes, `{correct: false, penalty_seconds: 10, error: ""}`
  - invalid input: nothing changes, `{correct: false, penalty_seconds: 0, error: "<reason>"}`.
    Invalid means: fuse_index not 0..2, not exactly 4 wires, unknown colour,
    a colour twice, fuse already solved.
- `lit_rooms(puzzle)`: rooms of solved fuses, derived, not stored.
- Invalid fuse index: `label_for` returns `[]`, `label_viewer` returns `-1`.
- Names and numbers (penalty, colours, symbols, rooms) live in `godot/scripts/settings.gd`.
  Wire colours: blue, yellow, white, black. Symbols: star, bell, tree, snowflake.

Note: GDScript has no exceptions (no raise, no try). So a rejection is a
return value with an error text, not a thrown error.

## Out of scope
Scenes and drawing, server, multiplayer, the clock, the attic, characters, and
everything on the "only if time" list: Santa pop-up, creaky floor, noise meter,
sound, abilities, Lisbon weather.

## Done when
- `godot/tests/test_fuse_rules.gd` covers every point above, was red first,
  and is green with (run from the repo folder):
  `godot --headless --path godot --script res://tests/run_tests.gd`
- Plausibility check: with a fixed seed, the label translated back through
  the legend equals the stored wire order.
