# Spec 24: Back to the hall through the door (living room, bedroom)

Owner: Mathies (small change in Lara's living room and in the bedroom)

## Why
Full test round (19.11.): the bathroom goes back to the hall by clicking its door, the living
room and the bedroom had a "Back to the hall" button. The rooms should work the same way.

## What
- Living room and bedroom: no "Back to the hall" button any more. Their open door in the
  picture is a click area named `DoorHall`:
  - living room: the open door right of the middle, next to the fireplace
    (`Rect2(726, 150, 178, 280)` on the 1152 x 648 stage);
  - bedroom: the open door on the left (`Rect2(0.035, 0.13, 0.215, 0.65)` of the room picture).
- Like the room's other click areas: invisible until the mouse is over it, then a frame,
  the hand cursor and the hint "Back to the hall". A click walks the team to the hall (`go_to`).

## Change after manual test (19.11., Mathies)
- All click areas in both rooms show the same gold frame on hover (`ffd76a`, 3 px), like the
  bathroom: in the living room also the clock and the note, in the bedroom also the calendar
  and the chest (they were copper or had no frame).
- The frames fit their objects: clock `Rect2(234, 112, 118, 395)` (crown to feet), poem on the
  mantelpiece `Rect2(986, 260, 66, 32)`, measured on the 1152 x 648 stage.
- The living room started on its own (Cmd R) now also goes to the hall scene through the door,
  like the bedroom. In the full game the door already worked (checked with a real mouse click).

## Out of scope
Arrow keys and Esc in these rooms (the shared room rules come next), new pictures.

## Done when
- The new and changed tests in `test_living_room_screen.gd` and `test_bedroom.gd` were red first
  and are green; all other tests stay green.
- Manual: in both rooms the door shows a frame and a hand on hover, and a click leads to the hall.
