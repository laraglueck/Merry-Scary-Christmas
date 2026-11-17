# Spec 11: Title screen

Owner: Leon

## Why
The game starts straight in the lobby with room codes and buttons. Players should first
see the game's title with its music and spoken intro, then choose to play. The artwork
(`ui_title.webp`), the music (`music_lobby.mp3`) and the voice (`voice_title.mp3`) are
already in `godot/assets/`.

## What
- New screen `godot/scenes/title.tscn` + `godot/scripts/title.gd`:
  - the full-screen picture `ui_title.webp` behind everything;
  - the game name "Merry Scary Christmas" (`TitleLabel`);
  - a `StartButton` "Start"; pressing it emits the signal `start_pressed`;
  - `music_lobby.mp3` plays in a loop (`Music`), `voice_title.mp3` plays once (`Voice`).
- `main.gd` shows the title first, on every device on its own (not shared over the
  network). After "Start" it shows the lobby as before.
- Once a game has started on this device the title does not come back: if the host
  leaves, everyone returns to the lobby, as before.
- The title screen started on its own (⌘ R) works too; "Start" then does nothing.

## Out of scope
Music in the lobby and the house, volume settings, skipping the voice, a credits or
settings screen, real title artwork (the placeholder stays until it is replaced).

## Done when
- The new tests in `tests/test_title.gd` and `tests/test_main.gd` were red first and are
  green; all older tests stay green.
- Manual: ▶ shows the title with music and voice; "Start" leads to the lobby.
