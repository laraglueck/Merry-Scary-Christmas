# Spec 15: Save and resume

Owner: Mathies

## Why
Team decision (17.11.): the game survives a restart, and starting over needs a confirmation.
Plot Twist asks that places remember their changes; a crash in the demo must not cost the run.

## What
- `godot/scripts/save_game.gd` (small file functions, no screens):
  - `path() -> String`: the save file. Normally `Settings.SAVE_PATH`
    (`user://saved_game.save`, Godot's data folder on the host's laptop, not the repo).
    If the environment variable `MERRY_SCARY_SAVE` is set, that path instead.
  - `save(game, path)`: writes the whole shared game; it loads back unchanged (same types).
  - `load_from(path) -> Dictionary`: the saved game, or `{}` when there is none or it is broken.
  - `exists(path) -> bool`, `remove(path)`.
- Tests never touch the real save: the test runner sets `MERRY_SCARY_SAVE` to a test file and
  deletes it before every test.
- `network.gd`, host only: after the start, after every action and after every clock tick the
  game is saved. When the game is over (phase is not `"hall"`, e.g. midnight) the save is
  deleted. `has_saved_game()`, `can_resume()` (like `can_start()`, and a save exists) and
  `resume_game()` (loads the save and sends it to everyone, the clock goes on from there).
- Lobby, host only:
  - "Resume saved game" while a save exists ("(needs 3 players)" until all are in).
  - "Start game" with a save asks first: "Start a new game? The saved game will be lost."
    with "Yes, new game" and "Cancel". Cancel keeps the save and starts nothing.
  - Start and Resume sit side by side, so the question fits on a 1152 x 648 window.

## Out of scope
Several save slots, saving on the players' laptops, players taking other numbers after a
resume (they get them in the order they join), saving before the game starts.

## Done when
- `tests/test_save_game.gd` and the new tests in `test_network.gd` and `test_lobby.gd` were red
  first and are green; all older tests stay green.
- Manual: three windows, play a bit, close all, start again: Resume brings back the clock,
  the fuses and the inventory. A new game asks first.
