# Spec 14: The inventory (what the team carries)

Owner: Mathies

## Why
Plot Twist asks for items that can be taken only once and an inventory that is always visible.
Team decision (17.11.): the three presents, the photo and the key show on every screen.
The rooms (Gloria, Leon, Lara) need one shared place to put what the team finds.

## What
- `settings.gd`: `ITEMS`, in this order, each with id, name and picture:
  `gift_1` "Present 1" (`item_gift_1.png`, living room), `gift_2` "Present 2"
  (`item_gift_2.png`, bathroom), `gift_3` "Present 3" (`item_gift_3.png`, bedroom),
  `photo` "Photo" (`egg_young_santa.png`, bedroom calendar), `key` "Key" (`item_key.png`, attic).
- The shared game gets `"inventory": []`, the ids of the items the whole team has, in the
  order they were found.
- `godot/scripts/rules/inventory_rules.gd` (pure; first check, then change):
  - `add(game, item) -> String`: puts the item in. Refused (returns the reason, changes
    nothing): an unknown item, or an item the team already has.
  - `has(game, item) -> bool`
- `game_rules.gd`: taking the bathroom's present puts `gift_2` into the inventory.
  The other rooms do the same with `InventoryRules.add` when they are built.
- `main.gd`: while the game runs, an inventory bar at the bottom right of every screen:
  five slots in the order of `ITEMS`. A slot with an item shows its picture and its name,
  an empty slot stays dark (no name, so it does not spoil what is still to find).
  Hidden before the game and after it. A missing picture (the photo for now) shows the
  name only.

## Out of scope
Using or giving away items (the key at the front door, the photo beside Santa: Lara),
the rooms' own presents (their owners), dragging items, real item artwork.

## Done when
- `tests/test_inventory_rules.gd` and the new tests in `test_main.gd` were red first and
  are green; all older tests stay green.
- Manual: three windows; the bathroom's present appears in the bar on all three.
