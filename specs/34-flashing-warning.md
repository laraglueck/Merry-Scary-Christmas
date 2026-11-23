# Spec 34: Flashing warning and "Reduce flashing"

Owner: Leon

## Why
The hall flickers like a loose bulb until the power is back (spec 05), and the title's window
light flickers too. Flickering light can cause seizures in people with photosensitive
epilepsy, and it is uncomfortable for others. Players should know before it starts, and be
able to switch it off.

## What
- **Warning first:** on each device, before the story, a dark screen says: "This game contains
  flickering lights that may affect people with photosensitive epilepsy." with a switch
  "Reduce flashing: Off / On" and "Continue" (also Enter or Space). Then the story starts as before.
- **Reduce flashing on:**
  - Hall: no flicker. The hall stays steadily a little dark instead (as dark as half the
    flicker's strength), and gets lighter with each fuse as before.
  - Title: the window light stays steadily dim, no flicker.
  - A room lighting up on the fuse plan glows softly instead of flashing bright.
- **Also during the game:** the pause screen has the same switch, so a player who feels
  unwell can switch it off without starting again.
- Only for this device (`Comfort.reduce_flashing`), until the game is closed.

## Out of scope
The bathroom's jump scare (a face and a short shake, once), remembering the choice after the
game is closed, a general "reduce motion".

## Done when
New tests (red first): the warning comes before the story and Continue leads to it; the
switch changes `Comfort.reduce_flashing`; with it on, the hall's overlay stays steady over
many steps, the title's window does not change, and the pause screen has the switch. The
tests that expect the story first skip the warning. All tests pass.
