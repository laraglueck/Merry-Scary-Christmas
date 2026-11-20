# Spec 27: Accessories for the figures

Owner: Leon

## Why
The character selection (spec 18) already had accessory arrows at head height, but only
"None (coming soon)". Now there are pictures of every figure in every colour with a bow,
a red nose or reindeer antlers, so each player can make their figure their own.

## What
- 27 new pictures in `godot/assets/images/`: `char_<figure>[_<colour>]_<accessory>.png`
  (red has no colour in the name, like the plain figures), e.g. `char_santa_bow.png`,
  `char_snowman_green_nose.png`, `char_nutcracker_yellow_antlers.png`. White background
  removed with `tools/add_image.gd`; listed in `tools/asset_names.gd`.
- `Settings.ACCESSORIES`: `none` ("None"), `bow` ("Bow"), `nose` ("Red nose"),
  `antlers` ("Antlers").
- `CharacterRules.picture_file(character, colour, accessory := "none")`: without an
  accessory the old file name, with one the name above.
- Character selection: `AccessoryPrev`/`AccessoryNext` go round all four accessories; the big
  figure, the card on the left and `AccessoryLabel` show the choice. Changing the colour or the
  figure keeps the accessory.
- The walking figures in the house (spec 19) wear the chosen accessory.

## Out of scope
More accessories, combining two accessories, accessories for Scary Jingles.

## Done when
- New tests in `test_character_rules.gd` (file names, all 36 pictures exist, arrows go round),
  `test_character_select.gd` (arrows change the big figure; accessory stays) and `test_hall.gd`
  (a figure in the hall wears its accessory) were red first and are green; all older tests stay green.
- Manual: in the selection the arrows at head height switch between no accessory, bow, red nose
  and antlers for each figure and colour.
