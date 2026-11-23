# Spec 34: Click to start in the browser, readable hall text, missing sounds

Owner: Gloria (small changes in the story screen (Leon), the hall (Mathies, the figures:
Leon), the bedroom (Mika) and main.gd; each is tagged in the pull request)

## Why
Playtest of the browser version on 23 Nov:
- The story's voice did not play at the URL: a browser blocks sound until the player has
  clicked the page once, and the story starts before any click.
- In the hall the walking figures covered the message text (they are drawn by depth, the
  text was drawn under them).
- "The pipes rattle angrily" had no sound of its own: only the short tap sound.
- Only the bedroom played a sound when something was picked up.
- The doll on the stairs only creaked; the scream of the bathroom mirror fits her better.

## What
- **Click to start (browser only):** before the story a line "Click to start" shows on the
  snowy night. The story, its subtitles and its time wait. The first click, Space or Enter
  starts the story (and so unlocks the sound); it does not skip it. In the Godot version
  nothing changes: the story starts at once, as before.
- **Hall text on top:** the message in the hall is drawn above the walking figures.
- **Pipes:** a wrong tap order plays a rattle (`sfx_key_lock.mp3`, the sound of the
  attic's rattling lock, lower) after the tap.
- **Picking up:** whenever something new comes into the team's inventory (a present, a
  photo piece, the photo, the cookies), every player hears `sfx_gift.mp3`, in every room.
  Not for what was already there when the game was joined or resumed. The bedroom's own
  present sound is taken out, so it does not play twice.
- **Doll:** the first time she turns, she screams (`sfx_scare.mp3`, the mirror's scream);
  every later time she creaks, as before.

## Out of scope
The music on/off button (spec 33, Leon), browser tab pause (spec 26) and more buffer for
crackling sound in the browser.

## Done when
New tests (red first): the browser start screen waits for a click and then plays the
story; the hall message is drawn above the figures; a wrong tap order rattles and a right
one does not; a picked-up item plays the sound on all three devices, and starting a game
does not; the doll screams first and creaks after. All tests pass. The web version is
exported again.
