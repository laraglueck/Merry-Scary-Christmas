# Spec 19: Figures that walk (step 1 of the "figures play the game" plan)

Owner: Leon

## Why
After the character selection (spec 18) every player has a figure, but the house still shows
none. The whole team walks from room to room together (spec 07). The goal of the next
specs is that each player's figure walks around on its own, in side view, with the keys W A S D;
that it must stand at an object to use it; that the figures have abilities; and that a noise
meter can wake Jingles. This spec is only the first, playable step: **walking**.

## Decisions so far (interview with Leon)
- Side view (2D), every figure on its own, everyone sees everyone live.
- Control (changed after the first test): **WASD**. A/D = left/right, W = into the room (further back, drawn
  smaller), S = towards you. Diagonals work, no jumping. Clicks do not move the figure.
- Later steps (not in this spec): each player in their own room with a house-plan overview,
  actions only at the right spot, abilities (Santa "Ho ho hint", Snowman "Freeze" 30 s, Nutcracker
  "Crack", once per game each; the fuse belongs to the figure: Santa red, Snowman green,
  Nutcracker gold), the noise meter (running, wrong tries and some actions make noise, it drops
  over time, a full meter wakes Jingles and the team loses).

## What (step 1)
- A reusable **walking layer** (one script + scene part, not written per room): it shows the
  figures of `game["characters"]` in the room, walks the own figure with W A S D, and shows
  the other figures walking, live.
- A room describes itself with a small piece of data only: floor line (where feet may stand,
  left/right limits), and later the standing spots of its objects and its doors. The room keeps its
  own puzzles. Rooms of other team members need no change except handing in this data.
- First, with the **hall** and the existing room pictures: try whether the pictures work for
  walking; the team decides afterwards whether rooms are redrawn.
- Positions: each device sends only which way its keys push (when they change); the host moves
  the figure with a fixed speed and sends the positions to everyone (about 10 times per second
  while someone moves, and once more when the last one stops). Left/right is faster than
  into the room. The floor is a **polygon** over the room picture (`Settings.FLOOR_HALL`): wide at the front, narrow at the back,
  the stairs cut out. A step into a wall slides along it (first only left/right, then only up/down). F3 shows the polygon
  as a red outline over the picture, so the points can be moved if a figure still walks into a wall.
- Depth: the further back (smaller y), the smaller the figure (`depth_scale`); a nearer figure is drawn over a farther one.
- The team still moves together between rooms (spec 07 stays); a figure's position is kept
  in `game["figures"]` = `{player: {"x", "y", "dx", "dy"}}` (feet position, key direction).

## Out of scope
Separate rooms per player and the house-plan overview (spec 20), actions only at the right spot
(spec 21), abilities and fuses per figure (spec 22), the noise meter (spec 23), puzzles that need
several figures (still open), accessory pictures, jumping.

## Done when
- Tests first (red), then green: rules for walking (target, speed, floor limits) as pure
  functions, the host sync, and the walking layer in the hall; all older tests stay green.
- Manual: three windows; in the hall everybody sees three figures; W A S D walk the own figure forward, back, left and right and the others see it.

## Open questions
- Do the existing room pictures have a usable floor? (decided by trying in the hall)
- How far the team adapts the other rooms, and when.
