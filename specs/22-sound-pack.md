# Spec 22: Sound pack (fuse click, music in the house, quieter menu music)

Owner: Mathies

## Why
Full test round (19.11.): solving a fuse makes no sound (`sfx_fuse_click.mp3` was a silent
placeholder), the house is silent while playing, and the menu music gets too loud after its
quiet start (it is a trailer track).

## What
- `sfx_fuse_click.mp3`: a short, real click (two metal clicks and a low thud, under 0.5 s),
  made with the program ffmpeg from noise and a low tone (own work, see CREDITS.md):
  `ffmpeg -f lavfi -i "anoisesrc=d=0.015:c=white:a=1" -f lavfi -i "anoisesrc=d=0.03:c=pink:a=1"
  -f lavfi -i "sine=f=85:d=0.3" -filter_complex "[0]highpass=f=1800,afade=t=out:st=0:d=0.015[a];
  [1]highpass=f=700,afade=t=out:st=0:d=0.03,adelay=60|60[b];[2]afade=t=out:st=0:d=0.3:curve=exp,
  volume=0.8,adelay=55|55[c];[a][b][c]amix=inputs=3:normalize=0,apad=pad_dur=0.05" -ac 1 -ar 44100
  -b:a 96k sfx_fuse_click.mp3`
- Hall: when a fuse goes on, its click plays: alone right after the right order, online on all
  three devices (whoever solved it). Coming back into the hall does not replay old clicks.
- `main.gd`: `music_house.mp3` loops quietly (`Settings.HOUSE_MUSIC_DB`, -18 dB) while the game
  runs in the house (phase `"hall"`, every room); it stops at the end screen and back in the lobby.
- The menu music (`music_lobby.mp3`) plays at `Settings.MENU_MUSIC_DB` (-10 dB) instead of 0 dB.
- In the headless tests nothing is really played; `main.house_music_on` and the hall's
  `sounds_played` say what would play.

## Out of scope
Sounds in the other rooms (their owners), the order of the screens (next spec), a volume slider.

## Done when
- New tests in `test_hall.gd` and `test_main.gd` were red first and are green; all older tests
  stay green.
- Manual: the click sounds like a fuse, the house music is quiet under the room sounds, the
  menu music is no longer too loud.
