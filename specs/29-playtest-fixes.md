# Spec 29: Fixes after the playtest of 20.11.

Owner: Mathies (small changes in Gloria's end screen and in Lara's living room window)

## Why
Full playtest (20.11.) with seven findings in the hall, the living room window and the end.

## What
1. Fuse box: the four symbols of "The order:" spread evenly over their frame (same gaps, as
   much room left as right), not packed at the left.
2. Wreath note: the greeting on its own line: "For Jingles, my best little elf." new line
   "Merry Christmas! – S."
3. The mission card shows once per game. It came back each time the team returned to the hall
   after a fuse was solved, because the card remembered the game together with the fuses'
   "solved" state. Now it remembers only what does not change in a game (legend and orders).
4. While the wreath note is open, the walking figures step aside (as for the mission card):
   they were drawn over the note.
5. Top right, in one row: "Penalty: 0 s", then the "?" (mission) and "Pause" side by side.
   Both are clear buttons: dark with a gold frame, lighter on hover, the hand cursor, 44 px high.
   Pause is top right on every screen, so the attic's "Back to the hall" moves left next to it:
   Pause covers no button in any room.
6. While someone looks out of the window, their inventory bar is hidden (it covered the lines
   under the window). The window view tells main.gd (group `hides_inventory`); it comes back
   when the view closes. Only on that device.
7. Merry Christmas ending: soft Christmas music, `music_merry.mp3`: "Silent Night" (Gruber, 1818,
   public domain) as a music box, made by `tools/make_music_merry.py` (own work), starting after
   1 s, then repeating. It replaces the silent placeholder
   `sfx_bells.mp3` there. Gentle snow falls over the picture (behind the words).
   The picture (Christmas Eve at night, decorated house and tree) comes from Gloria (Gemini);
   the end screen loads `ui_win_merry.webp`, so only the file needs to be replaced.
8. Scary Christmas ending: its own music, `music_scary.mp3`, made by `tools/make_music_scary.py`:
   the same "Silent Night" as a broken music box (minor key, out of tune, wobbling, a note that
   hangs, slowing down like a spring running out). Starts after 1 s like the Merry music, then repeats.
9. No drum fanfare (`sfx_win.mp3`) at the Merry and Scary endings any more: only their music
   (playtest 20.11.: it came first and did not fit).

## Out of scope
Sounds of the midnight ending, moving the clock.

## Done when
- New and changed tests in `test_hall.gd`, `test_main.gd` and `test_ending.gd` were red first and
  are green; all other tests stay green.
- Manual: the seven points look right in a three-window game.
