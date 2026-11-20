# Spec 28: Easter eggs behind the advent calendar doors

Owner: Leon

## Why
After the toy chest is solved, most bedroom calendar doors only say "Door N is empty."
Four of them now hide a small surprise picture (an idea already listed in `bedroom.md`).

## What
- 4 new pictures `egg_calendar_1.png` ... `egg_calendar_4.png` (512 px, white background removed
  with `tools/add_image.gd`, enclosed gaps too), listed in `tools/asset_names.gd`.
- `BedroomRules.egg_doors(room, clue) -> Array[int]`: the four egg doors, index i = egg i + 1.
  Never a clock-hand door, never the photo door. Derived from the saved state (wheels and
  digit), so it is random per game but the same after save/resume; no new save data.
- The egg doors open after the chest, like all other doors.
- Opening an egg door shows its picture **inside the door** (icon 80 px instead of 28 px).
  No close-up, no text, nothing goes to the inventory.
- Every egg plays `sfx_scare.mp3` the first time a player opens its door (changed after the manual
  test: first only egg 3 screamed). An egg door that is already open stays quiet.
- Opening is personal (only the opener sees and hears it, no network). Opened egg doors stay
  open on that screen for the rest of the game, also after leaving the bedroom (static memory per
  game, like the hall's mission card); a new game starts with all closed.

## Out of scope
Texts for the pictures, sharing the eggs with the team, more eggs.

## Done when
- `tests/test_bedroom_eggs.gd` was red first and is green; all older tests stay green.
- Manual: bedroom alone (offline), solve the chest. Four doors show a picture, each screams once, and the rest are empty. Close and reopen the calendar: the opened eggs are still there.
