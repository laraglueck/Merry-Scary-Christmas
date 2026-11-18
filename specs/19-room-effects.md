# Spec 19: Effects in the bathroom, the attic and the endings

Owner: Gloria (her own screens: bathroom, attic, end screen)

## Why
The puzzles work, but the rooms are quiet and still. The pictures and sounds for more
atmosphere already exist (asset checklist, Leon's sounds). This spec only changes how
the three screens look and sound; the rules and the shared game stay as they are.

## What

### Sounds on every device
- Each screen plays its sounds on every device, when the shared game shows that
  something happened (a teammate's turn too), not only for the player who clicked.
- In the headless test run nothing is played (no sound card; a sound still playing at
  the end shows up as a leak warning, like the title screen). Each screen keeps a list
  `sounds_played` with the file names it would have played, so tests can check it.

### Bathroom (`bathroom.gd`)
- **A turn of a tap:** `sfx_faucet.mp3`, cut off after 1.5 s.
- **The tub drains** (the taps are solved): `sfx_faucet.mp3` in full, lower and slower
  (pitch 0.7), so it gurgles.
- **Steam:** once solved, `prop_steam.png` rises over the mirror in the room (fades in
  and moves up a little) and stays. In the mirror close-up the steam lies behind the
  three symbols.
- **Face in the mirror:** the first time a player opens the mirror close-up, Jingles'
  face (`prop_mirror_face.png`) flashes in the glass for half a second, with
  `sfx_scare.mp3`. Once per player and game run (not every visit). It costs no time.

### Attic (`attic.gd`)
- **Snoring:** `sfx_snore.mp3` loops, quietly while the door is locked, louder once it
  is open.
- **Seen through the door:** while locked, Scary Jingles is already visible asleep on
  the right, dimmed like the room; the lock moves to the left so he can be seen.
- **He stirs:** after a wrong code (the team's penalty goes up while the attic is
  locked), the awake picture (`char_jingles_awake.png`) shows for one second, the
  snoring stops, then he is asleep again and the snoring goes on.
- **The lock opens:** `sfx_key_lock.mp3`.

### End screen (`ending.gd`)
- Merry Christmas: `sfx_win.mp3` and `sfx_bells.mp3`.
- Scary Christmas: `sfx_win.mp3`.
- Midnight: `sfx_lose.mp3`.

## Out of scope
The big jumpscare when the second room lights, the doll in the hall (Mathies' hall),
music changes near midnight (spec 13), sounds in the other rooms.

## Done when
- `test_bathroom.gd`, `test_attic.gd` and `test_ending.gd` have new tests that were red
  first and are green; all older tests stay green.
  - Bathroom: a turn plays the faucet; solving plays the gurgle and shows the steam
    (hidden before); the first mirror visit shows the face and plays the scare, the
    second does not; a teammate's turn (online) plays the faucet too.
  - Attic: Jingles is visible (asleep) while locked; a wrong code shows the awake
    picture; the right code plays the lock sound; the snoring is set up.
  - End screen: each ending plays its sounds.
- Manual: Cmd R on `bathroom.tscn` and `attic.tscn` with sound on.
