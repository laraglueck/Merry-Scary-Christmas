# Spec 21: The torn photo, the key, midnight, and tidier rooms

Owner: Gloria (attic, bathroom, end screen, photo puzzle). Parts in other rooms with the
owner's OK: living room (Lara), bedroom (Mika), inventory bar in main.gd (Mathies).

## Why
From the full test rounds (19 Nov): the photo could not be found, the key could not be
taken, nothing told the team why they might not lock Jingles in, the wide-awake Jingles
was never used, click areas slipped off their objects when the window was resized, and
the name labels on the objects spoil the pictures.

## What

### 1. Rooms stay right when the window is resized
Bathroom and attic (and, with Lara's OK, the living room) place everything in the
picture's own pixels, like the hall (spec 08b): the picture, its click areas and
everything on it move and scale together, whatever the window's shape.

### 2. No name labels on the objects
The click areas in the bathroom and living room show no names any more, except **Hot**
and **Cold** on the taps. A frame still shows on hover and with the arrow keys. The
hall keeps its labels (they say which doors are dark).

### 3. Jingles peeks instead of waking
New picture `char_jingles_peek.png`: asleep, one eye half open (same size as the other
two, they swap in the armchair).
- A wrong attic code: he **peeks** for a second (was: wide awake).
- Taking the key: he peeks for a second.

### 4. The key (attic)
- Once the lock is open, the key lies on the floor beside him and **no choice is shown**.
- Clicking the key: action `take_key`; the key goes into the inventory, he peeks, and
  the message says "You took the key. He didn't wake up... yet."
- Only then the two choices appear. "Lock him in" needs the key; "Leave the photo and
  cookies" needs the whole photo.
- Rules (`attic_rules.gd`): `take_key(attic)` refused while locked and the second time;
  `choose` refuses "lock_in" without the key. "Lock him in" no longer adds the key.

### 5. The photo in three torn pieces
- Items `photo_piece_1`, `photo_piece_2`, `photo_piece_3` (`settings.gd`), pictures
  `item_photo_piece_1/2/3.png` cut with torn edges from `item_photo.png` by a tool
  (`tools/cut_photo.gd`), so no new drawing is needed.
- Where they are:
  - bathroom: in the drained tub, beside the present (click it);
  - living room: inside the clock case once the clock is solved (Lara);
  - bedroom: behind the calendar door where the whole photo is now (Mika).
- Each piece shows in the inventory as soon as it is found.
- **Putting it together:** with all three pieces, clicking one in the inventory opens a
  small puzzle (`scenes/photo_puzzle.tscn`): the three pieces in a jumbled order; clicking
  two pieces swaps them; in the right order the torn edges fit. Then action
  `assemble_photo`: the three pieces leave the inventory and the whole `photo` is in it,
  with the message "The photo is whole again: Santa and a young, laughing Jingles."
- Rules in `photo_rules.gd`: which pieces exist, whether all are found, `assemble` (refused
  without all three or in the wrong order).

### 6. Midnight: he wakes up
Before the midnight end screen: the screen goes dark, the clock strikes
(`sfx_clock_chime`), and the wide-awake Jingles (`char_jingles_awake.png`) appears big in
the middle; after about five seconds the end screen (picture, title, presents) fades in.

### Later
Cookies (Gloria is thinking of something more creative), the pause button.

## Done when
- New tests, red first, then green; all older tests stay green:
  - attic: no choice before the key; the key goes into the inventory and he peeks; lock-in
    refused without the key; a wrong code shows the peeking picture;
  - photo rules: pieces, refused without all three or in the wrong order, the whole
    photo replaces the pieces;
  - bathroom: the piece in the tub can be taken once, after solving;
  - puzzle screen: swapping, the right order assembles;
  - end screen: midnight shows Jingles awake first;
  - resizing: a click area stays on its object in a narrow and a wide window.
- Manual: a full round in test mode (`-- test`), resizing the windows.
