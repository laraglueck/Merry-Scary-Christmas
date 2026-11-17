# Spec 12: Loading screen with the story

Owner: Leon

## Why
Before the title screen the players should hear who is behind it all: the fired helper
who steals three presents every Christmas Eve. The spoken story (`voice_title.mp3`,
ElevenLabs) and the music (`music_lobby.mp3`) already exist.

## What
- New screen `godot/scenes/intro.tscn` + `godot/scripts/intro.gd`, shown before the title,
  on every device on its own (nothing over the network):
  - a dark night with falling snow and dark edges (snow and gradient from `title.gd`);
  - the story as subtitles (`SubtitleLabel`), one line after the other, fading in and
    out; the lines are `STORY_LINES` in `intro.gd`;
  - each line appears at the second it starts in the recording (`LINE_START_SECONDS`,
    taken from the audio by hand);
  - the voice (`Voice`) plays once; when it ends the screen sends `finished`;
  - a click or a key skips: `finished` at once. A small hint says "Click to skip".
- The music moves to `main.gd` (`Music`, looping): it starts with the game, keeps playing
  through loading screen, title and lobby without a break, and stops when the game starts.
- The title keeps only its quiet wind; it has no music or voice of its own any more.
- `main.gd`: loading screen → title ("Start") → lobby. After a game ran on this device,
  game over leads back to the lobby, not to the loading screen or the title.

## Out of scope
Timing marks read from the audio file itself, other languages, a volume setting, a real loading
bar (nothing needs to load yet).

## Done when
- `tests/test_intro.gd` and the new tests in `test_main.gd` and `test_title.gd` were red
  first and are green; all older tests stay green.
- Manual: ▶ shows the story with the voice and music, the music goes on into the title,
  a click skips to the title.
