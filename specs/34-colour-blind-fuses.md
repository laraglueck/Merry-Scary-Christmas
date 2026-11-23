# Spec 34: Fuses not by colour alone

Owner: Leon (small change in Mathies' hall)

## Why
In the fuse box only the frame's colour (red, green or gold) tells whose fuse an order is
for. Red and green look alike to many colour-blind players (about 1 in 12 men), so for them
the hall's main puzzle cannot be worked out. The wires are fine: their names are written
above them, and the chosen order is listed in words.

## What
- Each fuse also has its own shape: red = circle, green = triangle, gold = diamond
  (`Settings.FUSES[i]["mark"]`). The shapes are drawn in code, in the fuse's colour with a
  dark edge (`scripts/fuse_mark.gd`).
- "Player 1, your fuse: RED" shows the own fuse's shape in front of the words.
- The frame around the order has the shape of its fuse as a small tag on its top edge,
  NOT in the row of symbols: a small fuse picture next to the symbols was taken out in the
  second test round because players read it as part of the order.
- The rescue hint names the shape too: "these symbols belong to the RED fuse (circle)".
- Playing alone (no frame) nothing changes.

## Out of scope
The bathroom's warm/cold taps, the symbols' own colours (they differ by shape already).

## Done when
New tests (red first): three different shapes; the title and the frame show the right
shapes for each player; the frame's shape is not in the row of symbols; the rescue hint
names the shape. All tests pass. Manual: a screenshot of the fuse box.
