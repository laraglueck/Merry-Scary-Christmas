# Assets brief (graphics, sounds and other assets)

## Context
- Team project for the course Introduction to Programming (Nova SBE). Team of 5, we build a Santa escape room horror game. Gameplay, tech stack and multiplayer are still being decided by the team.
- I am a complete beginner. My role: graphics, sounds and other assets. I must also contribute code to the repository.

## Style guide
- Colour palette: dark, red, brown, black, deep green
- Style: cartoon with thick outlines
- Mood: mystic, scary, creepy, quiet
- Setting: abandoned old house at night, faint candle light, snow outside

## Sizes and formats
- Room backgrounds: 1920x1080 px, WebP or JPG
- Items: 512x512 px, PNG with transparent background
- Characters: about 800 px tall, PNG with transparent background
- Buttons and icons: 128x128 px, PNG
- Sound effects: 1-5 seconds, MP3 or OGG, under 2 MB
- Music: loop of 1-2 minutes, MP3 or OGG, under 2 MB
- Every image under about 500 KB

## Proposed asset list (to be confirmed by the team)
- Rooms: entrance hall, living room with fireplace, kitchen, attic, cellar or toy workshop
- Items: rusty key, lantern, gift box, candy cane, music box, old photo
- Characters: creepy Santa, elves, gingerbread man
- Screens: title screen, win screen, game over screen, inventory frame
- Sounds: creaking door, footsteps, wind, whisper, key turning, distorted jingle bells, success chime, scare sound
- Music: quiet menu theme, tense background loop

## Folder and naming rules
- assets/images/ and assets/sounds/
- Names in lowercase with underscores and a type prefix, for example room_hall.webp, item_key.png, char_santa.png, sfx_door.mp3, music_theme.mp3
- assets/CREDITS.md lists for every file: name, source, licence, and whether AI was used (and which tool)
- File names must match the scene names in the game code. Check with the gameplay person.

## Tasks in order
1. Create the folders and a CREDITS.md template.
2. Create simple placeholder images (coloured rectangles with the file name written on them) and placeholder sounds, so the gameplay can be built before the real assets exist.
3. Create a small preview page that shows every image in assets/images and has a play button for every sound in assets/sounds. Use the stack the team decides on. If it is not decided yet, ask me.
4. Later: replace placeholders with the real assets, which I create outside of Claude Code with an image generator and free sound sites.

## Rules for Claude Code
- Explain every step in simple words and tell me what you will do before you do it. Think step by step.
- Work only in the assets/ folder, docs/assets-brief.md and the preview page. Do not change files of my teammates (game logic, tests, AGENTS.md) without asking me.
- Work on the branch assets. Never commit directly to main.
- No secrets, keys or passwords in the repository.
- Do not use copyrighted images, characters or music.
- Before every commit, show me the list of changed files and wait for my OK.
