# Spec 08: Hall artwork, clickable spots and close-ups

Owner: Mathies

## Why
The hall should look like Gloria's pictures, not like a form. It is the first room
everyone sees in the demo. Built the same way as the bathroom (spec 10): a picture,
see-through buttons over its parts, keys for everything.

## What (hall.gd, online and offline)
- Background: `room_hall.webp`, covering the screen.
- Six spots over the picture, left to right: fuse box, living room door, bathroom door,
  attic stairs, bedroom door, house plan. They keep their node names (`FuseBoxButton`,
  `Door_<place>`, `StairsButton`) plus `HousePlanButton`. Doors and stairs keep spec 07:
  "(dark)" and disabled until their fuse(s) are on.
- Keys: left/right move the highlight from spot to spot; Enter (or up) uses it;
  a dark door used by key explains which fuse to turn on.
- Fuse box close-up (`FusePanel`): `ui_fuse_box.webp`; four wire buttons over the four
  cables (blue, yellow, white, black, left to right); a fuse picture `item_fuse_<colour>.png`
  appears in its socket once that fuse is on, at socket size (about 56 x 104; bug from
  screenshot 2: it showed at its full 276 x 512). A side panel shows the player's fuse, the torn
  label as text and as four symbol pictures `sym_<symbol>.png`, the order so far as text and
  as colour bars in the wire colours, Reset and Back. (Change after the first screenshot:
  `wire_<colour>.png` are still one-colour placeholders, so bars show the order better.)
  Each cable's name stands above it. Keys: left/right choose a wire,
  Enter clicks it, Esc goes back.
- House plan close-up (`HousePlanPanel`): `ui_house_plan.webp`; each room on the plan is
  dark until its fuse is on, then glows (tiles and lamp texts from spec 05); the legend sits
  in the plan's empty box: per symbol its picture and "star = white". Esc or Back closes it.
- Spec change: the legend is four entries (`LegendEntry_<symbol>`, `LegendSymbol_<symbol>`)
  instead of one text block.

## Out of scope
Sounds (Leon), the wreath and doll easter eggs, inventory and clock on screen,
players in different places.

## Done when
- New tests in `tests/test_hall.gd` were red first and are green; all older tests stay green.
- Manual check in Godot with the table in the chat, plus a screenshot.
