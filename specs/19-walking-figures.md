# Spec 19: Figures that walk (step 1 of the "figures play the game" plan)

Owner: Leon

## Why
After the character selection (spec 18) every player has a figure, but the house still shows
none. The whole team walks from room to room together (spec 07). The goal of the next
specs is that each player's figure walks around on its own, in side view, with point-and-click;
that it must stand at an object to use it; that the figures have abilities; and that a noise
meter can wake Jingles. This spec is only the first, playable step: **walking**.

## Decisions so far (interview with Leon)
- Side view (2D), free walking in the room, every figure on its own, everyone sees everyone live.
- Control: point-and-click only. Click on the floor: the figure walks there. No jumping.
- Later steps (not in this spec): each player in their own room with a house-plan overview,
  actions only at the right spot, abilities (Santa "Ho ho hint", Snowman "Freeze" 30 s, Nutcracker
  "Crack", once per game each; the fuse belongs to the figure: Santa red, Snowman green,
  Nutcracker gold), the noise meter (running, wrong tries and some actions make noise, it drops
  over time, a full meter wakes Jingles and the team loses).

## What (step 1)
- A reusable **walking layer** (one script + scene part, not written per room): it shows the
  figures of `game["characters"]` in the room, walks the own figure to a clicked spot on the
  floor, and shows the other figures walking, live.
- A room describes itself with a small piece of data only: floor line (where feet may stand,
  left/right limits), and later the standing spots of its objects and its doors. The room keeps its
  own puzzles. Rooms of other team members need no change except handing in this data.
- First, with the **hall** and the existing room pictures: try whether the pictures work for
  walking; the team decides afterwards whether rooms are redrawn.
- Positions: each device sends where its figure is going; the host decides and sends the
  positions to everyone (about 10 times per second while someone moves). A figure walks with a
  fixed speed on every device, so the speed is the same everywhere.
- The team still moves together between rooms (spec 07 stays); a figure's position is saved
  in `game["figures"]` = `{player: {"x": float, "y": float, "target_x": float}}`.

## Out of scope
Separate rooms per player and the house-plan overview (spec 20), actions only at the right spot
(spec 21), abilities and fuses per figure (spec 22), the noise meter (spec 23), puzzles that need
several figures (still open), accessory pictures, jumping.

## Done when
- Tests first (red), then green: rules for walking (target, speed, floor limits) as pure
  functions, the host sync, and the walking layer in the hall; all older tests stay green.
- Manual: three windows; in the hall everybody sees three figures; a click on the floor
  makes the own figure walk there and the others see it.

## Open questions
- Do the existing room pictures have a usable floor? (decided by trying in the hall)
- How far the team adapts the other rooms, and when.
