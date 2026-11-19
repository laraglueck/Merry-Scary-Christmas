# Spec 23: New order of the screens (title, lobby, characters, story, hall)

Owner: Mathies

## Why
Full test round (19.11.): the story came before the title, so it was over before anyone
joined. The story should lead straight into the house: title, lobby, characters, story, hall.

## What
- Opening the game shows the title first (no story before it). "Start" leads to the lobby.
- When all three are ready in the character selection (spec 18), the game starts in a new
  phase `"intro"` instead of `"hall"`: everyone sees the story (spec 12) at the same time.
  - `GameRules.begin_intro(game)`: phase `"intro"`, `game["intro_done"] = []`.
  - Action `"intro_done"`: the player finished or skipped the story (counted once). When all
    three are done, the phase becomes `"hall"`. Every other action does nothing during the story.
  - The clock does not run during the story (it only ticks in `"hall"`), so 10:00 are left
    when the team enters the hall. A finished story cannot be "ended" with Back to the lobby.
- `main.gd`: when this player's story ends (voice over, click or key), it sends `"intro_done"`.
  Until the others are done it shows "Waiting for the others to finish the story...".
  The menu music goes on under the story; the house music starts in the hall.
- The story screen stays while the others still listen, so when it ends for this player it
  goes quiet: the voice stops, the line and "Click to skip" disappear (`intro.gd`, Leon's file).
- `network.start_game()` (quick start, used by the tests and by "-- test") still goes straight
  to the hall. A resumed game (spec 15) also goes straight to the hall.

## Change after manual test (19.11., Mathies)
- "Waiting for the others to finish the story..." sits in the middle of the screen.
- The menu music plays on the title only (not in the lobby, the selection or under the story).
- The story no longer starts suddenly: it fades in from black for `Settings.STORY_LEAD_IN_SECONDS`
  (2 s), then the voice starts. `intro.gd` gets `lead_in` (0 = as before, so it still works
  on its own) and `voice_started`.

## Out of scope
A shorter story, letting the host skip it for everyone, players who leave during the story.

## Done when
- New and changed tests in `test_game_rules.gd`, `test_network.gd` and `test_main.gd` were red
  first and are green; all other tests stay green.
- Manual: three windows; title, lobby, characters, story on all three, then the hall at 10:00.
