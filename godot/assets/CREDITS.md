# Asset credits

Every image and sound in `godot/assets/` needs one row in this table.
Add the row at the same time you add the file.
When real artwork replaces a placeholder, update its row: source, author, licence, AI used, and remove "placeholder" from Notes.

## How to fill in each column

- **File**: the exact file name, for example `item_key.png`.
- **Folder**: `images` or `sounds`.
- **Source**: where it comes from. Either "made by me", or the website plus a link to the exact page.
- **Author**: who made it (your name, or the creator's name on the website).
- **Licence**: the licence the file is under, for example `CC0`, `CC BY 4.0`, or "own work".
  If the licence needs attribution (like CC BY), write the required credit text in Notes.
- **AI used**: `No`, or `Yes` plus the tool name, for example `Yes (image generator name)`.
- **Notes**: anything else, for example "placeholder", "edited colours", or the attribution text.

## Images

| File | Folder | Source | Author | Licence | AI used | Notes |
|------|--------|--------|--------|---------|---------|-------|
| view_window_garden.png | images | made by `godot/tools/make_window_view.gd` from room_garden.webp and prop_moon_full.png | Mathies (from Gloria's pictures) | own work from AI pictures | Yes (the two source pictures) | the moon only shows where the picture is sky |
| view_window_garden_cloudy.png | images | made by `godot/tools/make_window_view.gd` from room_garden.webp and prop_moon_full.png | Mathies (from Gloria's pictures) | own work from AI pictures | Yes (the two source pictures) | the same with a pale moon behind clouds |
| room_garden.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | 1376 x 768 |
| room_hall.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | 1376 x 768 |
| room_attic.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | stairs come up at the front left |
| room_living_room_dark.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | door on the right as in the house plan |
| room_living_room_lit.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | door on the right as in the house plan |
| room_bathroom_dark.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | edit of room_bathroom_lit, lamp off; tub shows empty, to redo with water, 1376 x 768; mirrored so the door is on the right |
| room_bathroom_lit.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | 1376 x 768; mirrored so the door is on the right |
| room_bathroom_drained.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | edit of room_bathroom_lit, tub drained, 1376 x 768; mirrored so the door is on the right |
| room_bedroom_dark.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | door on the left as in the house plan |
| room_bedroom_lit.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | door on the left as in the house plan |
| char_snowman.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | white background removed with add_image.gd |
| char_santa.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | white background removed with add_image.gd |
| char_jingles_asleep.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | asleep in his armchair, hugging the sack; white background removed |
| char_jingles_peek.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | edit of char_jingles_asleep, one eye half open; white background removed |
| char_jingles_alert.png | images | edited from char_jingles_peek.png using OpenAI ChatGPT Images | Lara; original artwork by Gloria | AI-generated edit of team artwork | Yes (OpenAI ChatGPT Images; original: Google Gemini) | eye opened wider for the wrong-code reaction; transparent background; file size reduced by Gloria |
| char_jingles_awake.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | awake in the same armchair; white background removed |
| char_nutcracker.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | white background removed with add_image.gd |
| char_santa_green.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, white background removed with add_image.gd |
| char_santa_yellow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, white background removed with add_image.gd |
| char_snowman_green.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, white background removed with add_image.gd |
| char_snowman_yellow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, white background removed with add_image.gd |
| char_nutcracker_green.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green jacket, white background removed with add_image.gd |
| char_nutcracker_yellow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow jacket, white background removed with add_image.gd |
| char_santa_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, bow (spec 27), white background removed with add_image.gd |
| char_santa_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, red nose (spec 27), white background removed with add_image.gd |
| char_santa_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_santa_green_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, bow (spec 27), white background removed with add_image.gd |
| char_santa_green_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, red nose (spec 27), white background removed with add_image.gd |
| char_santa_green_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_santa_yellow_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, bow (spec 27), white background removed with add_image.gd |
| char_santa_yellow_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, red nose (spec 27), white background removed with add_image.gd |
| char_santa_yellow_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_snowman_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, bow (spec 27), white background removed with add_image.gd |
| char_snowman_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, red nose (spec 27), white background removed with add_image.gd |
| char_snowman_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_snowman_green_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, bow (spec 27), white background removed with add_image.gd |
| char_snowman_green_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, red nose (spec 27), white background removed with add_image.gd |
| char_snowman_green_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_snowman_yellow_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, bow (spec 27), white background removed with add_image.gd |
| char_snowman_yellow_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, red nose (spec 27), white background removed with add_image.gd |
| char_snowman_yellow_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow scarf, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_nutcracker_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red jacket, bow (spec 27), white background removed with add_image.gd |
| char_nutcracker_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red jacket, red nose (spec 27), white background removed with add_image.gd |
| char_nutcracker_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | red jacket, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_nutcracker_green_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green jacket, bow (spec 27), white background removed with add_image.gd |
| char_nutcracker_green_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green jacket, red nose (spec 27), white background removed with add_image.gd |
| char_nutcracker_green_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | green jacket, reindeer antlers (spec 27), white background removed with add_image.gd |
| char_nutcracker_yellow_bow.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow jacket, bow (spec 27), white background removed with add_image.gd |
| char_nutcracker_yellow_nose.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow jacket, red nose (spec 27), white background removed with add_image.gd |
| char_nutcracker_yellow_antlers.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | yellow jacket, reindeer antlers (spec 27), white background removed with add_image.gd |
| egg_calendar_1.png | images | provided by Leon (source to confirm) | Leon | to confirm | to confirm | Easter egg behind a bedroom calendar door (spec 28), white background removed with add_image.gd |
| egg_calendar_2.png | images | provided by Leon (source to confirm) | Leon | to confirm | to confirm | Easter egg behind a bedroom calendar door (spec 28), white background removed with add_image.gd |
| egg_calendar_3.png | images | provided by Leon (source to confirm) | Leon | to confirm | to confirm | Easter egg behind a bedroom calendar door (spec 28), white background removed with add_image.gd |
| egg_calendar_4.png | images | provided by Leon (source to confirm) | Leon | to confirm | to confirm | Easter egg behind a bedroom calendar door (spec 28), white background removed with add_image.gd |
| egg_calendar_5.png | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | Easter egg behind a bedroom calendar door (spec 28), white background removed with add_image.gd |
| item_fuse_red.png | images | generated with ChatGPT from our own text prompt | Gloria | AI-generated, own prompt | Yes (ChatGPT, model to confirm) | transparent background from ChatGPT |
| item_fuse_green.png | images | generated with ChatGPT from our own text prompt | Gloria | AI-generated, own prompt | Yes (ChatGPT, model to confirm) | transparent background from ChatGPT |
| item_fuse_gold.png | images | generated with ChatGPT from our own text prompt | Gloria | AI-generated, own prompt | Yes (ChatGPT, model to confirm) | transparent background from ChatGPT |
| item_gift_1.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | red ribbon, white background removed with add_image |
| item_gift_2.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | green ribbon, white background removed with add_image |
| item_gift_3.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | gold ribbon, white background removed with add_image |
| item_key.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background and the holes in the bow removed |
| item_house_plan.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| item_photo.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | Santa and the elf as friends; white background removed |
| item_photo_piece_1.png | images | cut from item_photo.png by `godot/tools/cut_photo.gd` | Gloria | own work (from our own AI picture) | Yes (from item_photo.png) | piece 1 of 3, torn edges drawn by the tool |
| item_photo_piece_2.png | images | cut from item_photo.png by `godot/tools/cut_photo.gd` | Gloria | own work (from our own AI picture) | Yes (from item_photo.png) | piece 2 of 3, torn edges drawn by the tool |
| item_photo_piece_3.png | images | cut from item_photo.png by `godot/tools/cut_photo.gd` | Gloria | own work (from our own AI picture) | Yes (from item_photo.png) | piece 3 of 3, torn edges drawn by the tool |
| item_cookies.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| prop_candle_lit.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_candle_out.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_1.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_2.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_3.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_4.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_5.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_6.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_7.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_8.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_steam_9.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| prop_calendar_open.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed with add_image |
| prop_calendar_closed.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed with add_image |
| prop_board.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white edge removed |
| prop_steam.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | black background made see-through, soft edges |
| prop_clock_face.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| prop_clock_hand_short.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background and holes removed |
| prop_clock_hand_long.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background and holes removed |
| prop_note.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| prop_wheel.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| prop_doll.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| prop_doll_turned.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | edit of prop_doll, head turned; white background removed |
| prop_mirror_face.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | black background made see-through |
| prop_moon_full.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | black background made see-through |
| sym_star.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background made transparent by `add_image.gd` |
| sym_bell.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background made transparent by `add_image.gd` |
| sym_tree.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background made transparent by `add_image.gd` |
| sym_snowflake.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background made transparent by `add_image.gd` |
| wire_blue.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| wire_yellow.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| wire_white.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| wire_black.png | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| ui_title.webp | images | Gemini (Google), generated image | Leon | own work (AI-generated) | Yes (Gemini) | house in the snow, background of the title screen |
| ui_win.webp | images | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| ui_win_merry.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | Merry Christmas ending; Christmas Eve night version since spec 29 (made from the old picture as reference) |
| ui_win_scary.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | Scary Christmas ending |
| ui_lose.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | midnight ending; edit of ui_win_scary |
| ui_fuse_box.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | modern box (19 Nov): ui_fuse_box_on with each breaker flipped down by `godot/tools/make_fuse_box.gd` |
| ui_fuse_box_on.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | the same box with all three breakers up |
| ui_house_plan.webp | images | frame and paper generated with Google Gemini from our own text prompt; the plan drawn by `godot/tools/draw_house_plan.gd` | Gloria | AI-generated, own prompt + own code | Yes (Google Gemini, Nano Banana 2.1) | old plan removed from the paper (`godot/tools/house_plan_paper.webp`), rooms match the hall |
| ui_clock.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | pocket watch; white background removed |
| ui_inventory.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background removed |
| ui_noise_meter.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background and the holes removed |
| ui_clock_hand.png | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | white background and the holes removed |
| ui_scare_face.webp | images | generated with Google Gemini from our own text prompt | Gloria | AI-generated, own prompt | Yes (Google Gemini, Nano Banana 2.1) | jumpscare face |

## Sounds

| File | Folder | Source | Author | Licence | AI used | Notes |
|------|--------|--------|--------|---------|---------|-------|
| sfx_fuse_click.mp3 | sounds | made with ffmpeg from noise and an 85 Hz tone (command in specs/22-sound-pack.md) | Mathies | own work | No | two metal clicks and a low thud, 0.44 s |
| sfx_spark.mp3 | sounds | Pixabay, original file `faespencer-high-voltage-spark-486895.mp3` | faespencer | Pixabay Content License | No |  |
| sfx_creak.mp3 | sounds | Pixabay, original file `dragon-studio-floorboard-creak-03-499651.mp3` | DRAGON-STUDIO | Pixabay Content License | No |  |
| sfx_snore.mp3 | sounds | Pixabay, original file `audiopapkin-male-snoring-297875.mp3` | audiopapkin | Pixabay Content License | No |  |
| sfx_wind.mp3 | sounds | Pixabay, original file `dragon-studio-winter-wind-402331.mp3` | DRAGON-STUDIO | Pixabay Content License | No |  |
| sfx_bells.mp3 | sounds | `godot/tools/make_placeholders.gd` | team script | own work | No | placeholder |
| sfx_gift.mp3 | sounds | Pixabay, original file `universfield-magic-surprise-141291.mp3` | Universfield | Pixabay Content License | No |  |
| sfx_scare.mp3 | sounds | Pixabay, original file `alex_jauk-sudden-screaming-sound-193070.mp3` | alex_jauk | Pixabay Content License | No |  |
| sfx_win.mp3 | sounds | Pixabay, original file `emand_edroff-victory-bell-success-fanfare-576275.mp3` | emand_edroff | Pixabay Content License | No |  |
| sfx_lose.mp3 | sounds | Pixabay, original file `emand_edroff-comedic-trombone-disappointment-576276.mp3` | emand_edroff | Pixabay Content License | No |  |
| sfx_faucet.mp3 | sounds | Pixabay, original file `alex_jauk-squeaky-old-faucet-197041.mp3` | alex_jauk | Pixabay Content License | No |  |
| sfx_drain.mp3 | sounds | original file `vsx-bathtub-water-draining.mp3`, website to confirm | to confirm | to confirm | to confirm | the tub drains when the taps are solved |
| sfx_steam.mp3 | sounds | original file `vsx-steam-hissing.mp3`, website to confirm | to confirm | to confirm | to confirm | the steam rises over the mirror |
| sfx_clock_tick.mp3 | sounds | Pixabay, original file `dragon-studio-slow-cinematic-clock-ticking-357979.mp3` | DRAGON-STUDIO | Pixabay Content License | No |  |
| sfx_clock_wrong.mp3 | sounds | Pixabay, original file `freesound_community-metal-scraping-47621.mp3` | freesound_community | Pixabay Content License | No |  |
| sfx_clock_chime.mp3 | sounds | Pixabay, original file `freesound_community-clock-chime-88027.mp3` | freesound_community | Pixabay Content License | No |  |
| sfx_door_unlock.mp3 | sounds | Pixabay, original file `dragon-studio-heavy-door-unlocking-515258.mp3` | DRAGON-STUDIO | Pixabay Content License | No |  |
| sfx_key_lock.mp3 | sounds | Pixabay, original file `hasin2004-key-lock-sound-247454.mp3` | hasin2004 | Pixabay Content License | No |  |
| sfx_easter_egg.mp3 | sounds | Pixabay, original file `dragon-studio-bells-jingling-2-372467.mp3` | DRAGON-STUDIO | Pixabay Content License | No |  |
| sfx_rain.mp3 | sounds | Pixabay, original file `boons_freak-rain-sound-188158.mp3` | boons_freak | Pixabay Content License | No | 2.9 MB, above the 2 MB guideline |
| sfx_storm.mp3 | sounds | Pixabay, original file `sarthakraj_308-heavy-wind-storm-326096.mp3` | sarthakraj_308 | Pixabay Content License | No |  |
| music_lobby.mp3 | sounds | Pixabay, original file `audioatlant-evil-jingle-christmas-horror-trailer-version-635742.mp3` | audioatlant | Pixabay Content License | No | 2.4 MB, above the 2 MB guideline |
| music_house.mp3 | sounds | Pixabay, original file `cinematic-soul-dark-ambient-background-music-617907.mp3` | check on Pixabay | Pixabay Content License | No |  |
| voice_title.mp3 | sounds | ElevenLabs (elevenlabs.io), generated voice | Leon | check ElevenLabs plan terms | Yes (ElevenLabs) | spoken intro for the title screen |
| music_merry.mp3 | sounds | made by `godot/tools/make_music_merry.py` (sine-wave music box) | Mathies; melody "Silent Night" by Franz Xaver Gruber (1818) | own work; the melody is public domain | No | Merry Christmas ending, starts after 1 s, loops |
| music_scary.mp3 | sounds | made by `godot/tools/make_music_scary.py` (sine-wave music box, out of tune) | Mathies; melody "Silent Night" by Franz Xaver Gruber (1818) | own work; the melody is public domain | No | Scary Christmas ending, a broken music box, starts after 1 s, loops |
| voice_jingles_whos_at_the_door.wav | sounds | original recording by a friend of Lara | Friend of Lara | Used with the speaker's permission | No | "Who's at the door?"; recorded as M4A, converted to mono WAV and trimmed by 3 seconds using FFmpeg |