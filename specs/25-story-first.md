# Spec 25: The story first, before the title

Owner: Leon

## Why
The story should set the mood before the players meet, not between the character
selection and the hall. New order: story, title, lobby, characters, hall.

## What
- Opening the game shows the story (spec 12) on this device, with the fade-in from
  spec 23. When the voice ends, or on a click, Space, Enter or Esc, the title follows,
  and "Start" leads to the lobby.
- Every player sees the story on their own device, at their own pace, before the title. Nobody waits for the others.
- When all three are ready in the character selection (spec 18), the game starts straight
  in the hall at 10:00. The `"intro"` phase from spec 23 (`begin_intro`, `"intro_done"`,
  "Waiting for the others to finish the story...") is gone.
- Back to the lobby after a game (spec 17) does not show the story again.
- The menu music still plays on the title only.

## Done when
- Changed tests in `test_main.gd` and `test_network.gd` were red first and are green; the
  spec 23 phase tests in `test_game_rules.gd` are removed; all other tests stay green.
- Manual: three windows; story, title, lobby, characters, then the hall at 10:00.
