# Spec 13: The clock (10 minutes until midnight)

Owner: Mathies

## Why
Team decision (17.11.): the team has 10 minutes; every penalty is taken off the clock, and
midnight is the loss. Until now penalties were only counted (`penalty_seconds`), no time ran.
Lara's endings need the loss ("Midnight").

## What
- `settings.gd`: `GAME_SECONDS := 600`, `CLOCK_WARNING_SECONDS := 60`.
- The shared game gets `"seconds_played": 0`. Time left is derived, not stored:
  `GAME_SECONDS - seconds_played - penalty_seconds`, never below 0.
- `godot/scripts/rules/clock_rules.gd` (pure; first check, then change):
  - `time_left(game) -> int`
  - `tick(game, seconds) -> String`: adds whole seconds to `seconds_played`. Refused (returns
    the reason, changes nothing): seconds below 1, or the game is no longer running.
  - `check_midnight(game)`: time left 0 while the game runs -> `phase` becomes `"midnight"`,
    `last_event` "Midnight! Santa Scare is awake. The team has lost."
  - `as_text(seconds) -> String`: 598 -> "09:58".
- `game_rules.gd`: while `phase` is not `"hall"`, every action is refused and changes
  nothing. After every action, `check_midnight` (a penalty can strike midnight).
- `network.gd`: only the host counts. `advance_clock(delta)` (called every frame) collects
  time; every whole second it ticks the game and sends it to everyone.
- `main.gd`: while the game runs, every screen shows "Midnight in 09:58" at the top centre;
  in the last minute in red. Hidden before the game and after it.
- Until Lara's end screens exist, `"midnight"` shows the placeholder screen with the title
  "Midnight" and no "Back to the hall". The placeholder's text sits in the middle of the
  screen (it grew to the right of the middle before).

## Out of scope
End screens and "play again" (Lara), pausing, saving the clock (spec for save and resume),
the clock in hall.tscn started on its own (no host there), sounds.

## Done when
- `tests/test_clock_rules.gd` and the new tests in `test_network.gd` and `test_main.gd`
  were red first and are green; all older tests stay green.
- Manual: three windows show the same clock; a wrong fuse takes 10 s off on all three.
