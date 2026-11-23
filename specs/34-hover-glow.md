# Spec 34: Clickable things glow on hover

Owner: Leon (touches every room: Lara, Gloria, Mika and Mathies are tagged in the pull request)

## Why
Players should spend their time on the puzzles, not on hunting for the one pixel that can be
clicked. Until now the click areas showed a hard gold frame on hover, and the things you can
pick up (presents, photo pieces, cookies, the key, the doll's note) only changed the cursor.

## What
- One shared look in `scripts/hover_glow.gd`, used by every room and the hall.
- **Click areas over the picture** (doors, window, clock, note, fuse box, stairs, house plan,
  wreath, bathtub, taps, mirror, calendar, toy chest): on hover a soft warm glow instead of the
  hard frame: a thin gold edge, a faint gold fill and a soft gold halo around it.
- **Things to pick up** (`TextureButton`s): on hover they light up a little and get a soft gold
  halo behind them. When the mouse leaves they look as before (also the dimmed doll's note).
- Still the hand cursor on all of them. Nothing glows without the mouse over it, so the search
  stays a search.

## Out of scope
Glow on the menu buttons and the close-up puzzles (they are buttons already), a glow that
shows all click areas at once.

## Done when
New tests (red first): the shared glow style; a thing to pick up lights up on hover and goes
back after; every click area and every thing to pick up in the hall, living room, bathroom,
bedroom and attic uses the glow. All tests pass.
