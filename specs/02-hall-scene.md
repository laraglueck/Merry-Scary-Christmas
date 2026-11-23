# Spec 02: Hall scene with fuse box

Owner: Mathies (hall + fuses)

## Why
First thing we can show: the hall where the team plays the fuse puzzle.
For now everything runs on one screen; a player switch stands in for separate devices.

## What
Scene `godot/scenes/hall.tscn` with script `godot/scripts/hall.gd`.
The rules stay in `fuse_rules.gd`; the scene only shows them and reacts to clicks.

- House plan: legend (symbol = colour) and one lamp per room
  (living/dining room, bathroom, bedroom): "dark" until its fuse is solved, then "lit".
- Player switch (Player 1, 2, 3 = player index 0, 1, 2) and a penalty counter ("Penalty: 0 s").
- Fuse box button opens the fuse panel. The panel shows:
  - the current player's own fuse (Player 1 = red, Player 2 = green, Player 3 = gold),
  - the torn label this player can see: the label of the fuse whose `label_viewer` is this player,
  - 4 wire buttons (blue, yellow, white, black) and the order clicked so far,
  - a Reset button that clears the order.
- A clicked wire button is disabled, so a colour cannot be chosen twice.
- After the 4th wire the attempt goes to `try_fuse` automatically:
  - right: the room lamp turns "lit", a message says the fuse is on;
  - wrong: penalty counter +10 s, message shows the penalty, order is cleared.
- A solved fuse cannot be played again (wire buttons disabled, "already on").
- Switching player clears a half-finished order.
- Each start gives a new random puzzle; `seed_value` fixes it for tests.
- Everything fits in the game window (1152 x 648): after opening the fuse box, the
  penalty counter, the fuse panel, the last room lamp and the message lie fully inside
  the window, and the penalty counter is one line (bug from manual test 1).

## Out of scope
Artwork, flicker effect, sound, network and room codes, the clock,
the rooms' content (gifts, digits), the attic.

## Done when
- `godot/tests/test_hall.gd` presses the buttons like a player, was red first, is green.
- All tests green with `godot --headless --path godot --script res://tests/run_tests.gd`.
- Manual check in Godot (F6 on hall.tscn) following the table in the chat.
