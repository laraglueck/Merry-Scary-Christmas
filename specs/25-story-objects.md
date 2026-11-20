# Spec 25: A story object in the hall (the wreath)

Owner: Mathies

## Why
Full test round (19.11.): the house should tell more of the story, with things you can click
that are not part of a puzzle. They prepare the twist: Scary Jingles was once Santa's helper,
loved by him, until the storm night.

## What
- A new spot in the hall, measured on `room_hall.webp` (picture pixels, 1376 x 768):
  `wreath`, node `StoryWreath`: the dried wreath on the living room door, `Rect2(198, 146, 112, 250)`.
  It lies on top of the door: a click on the wreath shows its story, a click on the rest of
  the door still opens the door.
- Like every spot: no name on it, a gold frame and the hand cursor on hover, the hint
  "A dried-up wreath". The arrow keys reach it in left-to-right order:
  fuse box, living room, wreath, bathroom, stairs, bedroom, house plan.
  All hall spots now show the hand cursor.
- A click (or Enter) shows a small note (`StoryCard`, text `StoryText`) on this device only:
  "A dried-up wreath. A faded tag still hangs from the bow: "For Jingles, my best little elf.
  Merry Christmas! – S."", with faint jingling bells (`sfx_easter_egg.mp3`, 2 s).
- After the manual test (19.11.): the lantern was dropped; "my best little elf" instead of
  "my most loyal helper" (the intro already says "loyal", and it tells that Jingles is an elf).
- Esc, Enter or a click anywhere closes the note. It costs no time, sends nothing to the host
  and changes nothing in the game.

## Out of scope
Story objects in the other rooms (their owners, same idea), new pictures, collecting the
stories in the inventory.

## Done when
- New and changed tests in `test_hall.gd` were red first and are green; all other tests stay green.
- Manual: both objects show a frame on hover, the note and the sound; the door still opens.
