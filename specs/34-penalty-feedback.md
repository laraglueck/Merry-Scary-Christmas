# Spec 34: You can see a penalty

Owner: Leon

## Why
A wrong code costs 10 or 20 seconds, but the only sign was the clock jumping. Players
did not notice they had lost time.

## What
- When the team's penalty grows (any wrong answer in any room, by any player), every
  player sees it at once:
  - a red "−20 s" (the seconds just lost) under the clock that floats up and fades out
    (about 1.2 s);
  - a short shake of the screen (about 0.35 s). The clock, the inventory and the buttons
    do not shake.
- Not when the game is loaded or resumed with penalties already in it, only when it grows.
- Shown by `main.gd` from `net.game["penalty_seconds"]`; the rules do not change.

## Out of scope
Sounds for a penalty, a shake for other events.

## Done when
New tests (red first): a wrong fuse shows "−10 s" on all three screens and shakes the
screen; no float and no shake at the start of a game. All tests pass.
