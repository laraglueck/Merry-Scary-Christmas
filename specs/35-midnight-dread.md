# Spec 35: The last five minutes get scary

Owner: Leon

## Why
Up to now the only pressure at the end is the clock turning red in the last minute. A horror
game should build up to its ending, so midnight feels earned and the last minutes are the
part people remember.

## What
Two stages, worked out from the time left (`ClockRules.dread_stage`), on every device and
every screen while the game runs (not while paused):
- **Stage 1, 5 minutes left (`Settings.DREAD_SECONDS`, 300):**
  - the house music plays a little faster and higher (`Settings.DREAD_MUSIC_PITCH`), as if
    the tape were wearing out;
  - Jingles' snoring (`sfx_snore.mp3`) can be heard quietly in every room
    (`Settings.DREAD_SNORE_DB`); the attic keeps its own, louder snoring.
- **Stage 2, 2 minutes left (`Settings.PANIC_SECONDS`, 120):**
  - the music faster still (`Settings.PANIC_MUSIC_PITCH`);
  - the lights flicker on every screen, also in rooms with power (a dark layer under the
    clock and the inventory; clicks go through);
  - once, a short shot of Jingles twitching in his sleep (`char_jingles_peek.png` flashes
    over the screen for about a second).
- **A clock chime** (`sfx_clock_chime.mp3`) at every full minute in the last five
  (5:00, 4:00, 3:00, 2:00, 1:00 left), once each (`ClockRules.chime_due`). A penalty that
  jumps over a full minute rings it too.
- In the headless tests nothing is played; `main.dread_stage` and `main.dread_sounds` say
  what would happen.

## Out of scope
New sounds or pictures, changes to the hall's own flicker, the midnight ending itself.

## Done when
New tests (red first): the stages from the time left, the chimes (each full minute once,
none above 5 minutes, one over a penalty jump), main in stage 1 and 2 (music pitch, snore,
flicker, Jingles shot once), nothing during pause, back to normal in a new game. All tests pass.
