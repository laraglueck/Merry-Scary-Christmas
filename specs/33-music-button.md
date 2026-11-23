# Spec 33: Music on/off button

Owner: Leon

## Why
Some players want the room sounds and the voices, but not the music (e.g. while talking
over a call). Up to now the music could not be switched off.

## What
- A small square button in the top left corner, on every screen (story, title, lobby,
  character selection, every room, the endings), above the screens like the clock.
- It shows a music note (drawn in code, no emoji and no new picture). Music on: the note in
  cream. Music off: the same note, crossed out with a slanted line, and the whole button a
  little greyed out.
- A click switches it. Off pauses the menu music, the house music and the endings' music; on lets them go on
  from where they stopped. Room sounds, voices and the story are not changed.
- Only for this device (not shared with the team); it stays as it is from screen to screen
  until the game is closed.
- Tooltip: "Music off" / "Music on" (what a click does).

## Out of scope
Volume slider, remembering the choice after the game is closed, muting the room sounds.

## Done when
New tests (red first): the button is there on the title and in the hall; a click turns the
music off (both music players paused, note crossed out, button greyed) and a second click on
again; it does not overlap the other buttons in the hall. All tests pass.
