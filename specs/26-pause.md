# Spec 26: Pause for everyone

Owner: Leon

## Why
A real break (doorbell, phone, a question) should not cost the team time. The game needs a
pause that stops the clock for all three players at once.

## What
- `game["paused"]` (false in a new game) and `game["paused_by"]` (player index, -1 if none).
- Actions (only while the game runs in the house, phase `"hall"`):
  - `"pause"`: any player pauses the game for everyone. `last_event` says "Player 2 paused the game".
  - `"resume"`: any player continues, no matter who paused.
  - While paused, every other action does nothing.
- The clock does not tick while paused (`ClockRules.tick` refuses), so no time runs out.
- The figures stop: pausing clears everyone's walking direction, and the host does not move
  them while paused.
- `main.gd`: a `PauseButton` ("Pause") at the top right, shown only while the game runs in the
  house. While paused, `PauseOverlay` darkens every screen on all three devices and blocks clicks:
  "Paused by Player 2" (`PauseLabel`) and a `ContinueButton` ("Continue") that everyone can press.
- A saved game (spec 15) keeps the pause; after resuming it the team presses Continue.
- In the browser, changing tabs or leaving the browser window pauses the game and its
  audio. On return, the pause overlay waits for Continue. Audio resumes where it left off,
  preserving the music switch. This also applies to the story, menus and endings, but not
  to the warning and "Click to start": nothing runs there yet, so there is nothing to pause.

## Out of scope
Pausing room sounds and animation with the team's manual Pause button, and a pause key.

## Done when
- New tests in `test_game_rules.gd`, `test_clock_rules.gd` and `test_main.gd` were red first and
  are green; all other tests stay green.
- Manual: three windows; Player 2 pauses, the clock stops on all three; Player 3 continues.
