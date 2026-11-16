# Spec 06: Asset folders and placeholders

Owner: Gloria (assets and interface)

## Why
The scenes need images and sounds under fixed names before the real artwork exists.
With a placeholder for every name, the hall, the rooms and the attic can be built now,
and each real file later replaces a placeholder without any code change.

## What
- The asset folders live inside the Godot project, because Godot only loads files
  from its own folder: `godot/assets/images/`, `godot/assets/sounds/`,
  `godot/assets/CREDITS.md`.
- `godot/tools/asset_names.gd`: the one list of every asset file the game expects,
  with the pixel size of each image. Names follow the shared contract: lowercase,
  underscores, a type prefix (`room_`, `char_`, `item_`, `prop_`, `sym_`, `wire_`,
  `ui_`, `sfx_`, `music_`).
- `godot/tools/make_placeholders.gd`: for every name in the list that has no file yet,
  - an image: one flat colour per type with a darker border, at the listed size,
    saved as PNG or WebP according to the file name;
  - a sound: about half a second of silence as a valid MP3.
- An existing file is never overwritten, so the script is safe to run again after
  real artwork has been added.
- `godot/assets/CREDITS.md` has one row per file, marked "placeholder".

Run from the repo folder:

    godot --headless --path godot --script res://tools/make_placeholders.gd

Then open the project once in the Godot editor, so it creates the `.import` file
beside each asset, and commit those too.

## Out of scope
Real artwork and sounds, the asset preview scene, the asset test (file sizes,
missing names, missing credits), the title screen. Text on the placeholders:
the preview scene will show each file name instead.

## Done when
- Every name in `asset_names.gd` exists as a file under `godot/assets/`.
- Running the script a second time creates nothing and reports every file as kept.
- The existing tests are still green:
  `godot --headless --path godot --script res://tests/run_tests.gd`.
- Manual check in Godot: the files appear in the FileSystem panel and a sound plays
  (silently) without an error.
