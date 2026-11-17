# Spec 08b: Hall polish after manual test 2

Owner: Mathies

## Why
Manual test on Mathies' Mac (17.11.):
1. The house plan's room fields and legend sat next to the rooms: the window had another
   shape than 1152 x 648, the picture grew, the fields did not.
2. Keys did nothing after a mouse click: the clicked button kept the keyboard focus and
   Godot used the arrows and Enter for itself.
3. Wish: drag the cables to their place instead of only clicking them.
   (Taken back after manual test 3, see below.)
4. Wish (after manual test 3): the symbols star, bell, tree and snowflake in colour.

## What
- Pictures keep their shape (fit, centred) in any window. Every spot, wire, contact and room
  field is placed in picture pixels (1376 x 768) and moves and scales with the picture.
- No button in the hall takes the keyboard focus, so left/right, Enter and Esc always reach
  the hall, also after a mouse click.
- House plan, clean: each room field covers exactly its room on the plan (square corners);
  dark = darkened, lit = the room's own colour with a warm edge; its text is the room's short
  name and "dark" or "lit". The legend sits centred in the plan's inner box, one line per
  symbol: picture and "star = white".
- Fuse box: cables are only clicked (or chosen by keys), and the order of the clicks is the
  order tried (as in spec 02). No dragging, no contacts on the door, no lines.
- Symbols in colour, in the hall only (torn label and legend): each symbol has its own fixed
  colour, star gold, bell red, tree green, snowflake ice blue. Fixed, NOT the wire colour from
  the legend: the legend is shuffled every game, and a symbol in its wire colour would give the
  answer away on the torn label. The pictures stay Gloria's files (`sym_<symbol>.png`, also used
  in the bathroom); the hall only tints them.

## Change after manual test 3 (17.11., Mathies)
- Dragging felt like too much: back to clicking the cables in order (see "What").
- Torn label: only its four symbol pictures, no list of their names. The text still says whose
  fuse it belongs to and "Read it out to its owner!". The pictures speak for themselves.

## Change after manual test 4 (17.11., Mathies)
- Torn label text: the fuse's name ("gold", "red", "green") in that fuse's colour.
- A bit more room between the fuse panel's title and the torn label text.

## Out of scope
Sounds, real wire artwork,
coloured symbols in the bathroom (Gloria's screen).

## Done when
- New tests in `tests/test_hall.gd` were red first and are green; all older tests stay green.
  Keys in the tests go through the viewport (`push_input`), like real key presses.
- Rendered screenshots at 1152 x 648 and at another window shape look right.
