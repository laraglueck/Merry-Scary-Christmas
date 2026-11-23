# Spec 07: Walking through the house (doors and stairs)

Owner: Mathies

## Why
The rooms (living room, bathroom, bedroom) and the attic need a way in. Team decision
(17.11.): the team walks together, so everyone always sees the same place.

## What
- Places: `hall`, `living_room`, `bathroom`, `bedroom`, `attic`. The shared game gets
  `"location": "hall"` at the start. `settings.gd` gives each fuse its place
  (red = `living_room`, green = `bathroom`, gold = `bedroom`).
- `godot/scripts/rules/house_rules.gd` (pure): `go_to(game, place)` returns `""` or the
  reason it is refused; refused changes nothing:
  - unknown place, or the team is already there;
  - from a room only back to the hall ("every room is reached from the hall");
  - a room whose fuse is off ("The bathroom is still dark. Turn on the green fuse first.");
  - the attic before all three fuses are on ("The stairs are pitch dark ...").
- `game_rules.gd`: action `"go_to"` with `{place}`; the event names the player, e.g.
  "Player 2 opened the bathroom door." A refused move shows its reason as the event.
- `main.gd` shows the screen for the team's location while the game runs. Bathroom =
  Gloria's `bathroom.tscn`; living room, bedroom and attic get a placeholder screen with
  the room's name and "Back to the hall" until their owners add theirs to `SCREENS`.
- Hall: a door button per room ("(dark)" and disabled while its fuse is off) and the
  attic stairs (disabled until all three fuses are on). Online a click sends `go_to`;
  alone (hall.tscn started on its own) it explains that walking needs the full game.
- Bathroom: its `door_hall` spot now walks the team back to the hall.

## Out of scope
The hall artwork and clickable spots in the picture (spec 08), sounds, the clock,
the attic lock itself (Lara), players in different places.

## Done when
- `tests/test_house_rules.gd` and the new tests in `test_game_rules.gd`, `test_hall.gd`
  and `test_main.gd` were red first and are green; all older tests stay green.
- Manual: three windows walk together from the hall into a lit room and back.
