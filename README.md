# Merry Scary Christmas

A Christmas escape room for **one or three players**, made with **Godot 4.7** for the
course *Introduction to Programming* at Nova SBE (fall 2026).

Scary Jingles, Santa's former helper elf, has stolen three presents and hidden them in his
dark old house. The team has **20 minutes until midnight** to turn the power back on, solve
the puzzles in the living room, bathroom and bedroom, collect the presents, a torn photo and
the cookies, and open the attic. There they decide his fate: lock him in (**Scary Christmas**) or leave
him the photo of his happier days and the cookies (**Merry Christmas**). If the clock strikes twelve, he wins.

Every hero has one power per game: Santa's **Ho ho hint**, the Snowman's **Freeze**
(+30 seconds) and the Nutcracker's **Crack** (part of an answer). The fastest wins go on a
**leaderboard** on the end screen, with a countdown to Christmas Eve.

## Team

| Name | Student number | Main parts |
| --- | --- | --- |
| Gloria Bogea Heinzel | 79191 | bathroom, attic, end screens, all pictures, single player, hero powers, leaderboard, cookies |
| Lara Victoria Glück | 70426 | living room, clock lock, rhyme |
| Leon Blieffert | 73695 | title and story, characters and accessories, walking, sounds, pause |
| Carl Mathies Rumohr | 71317 | hall and fuse box, network, clock, inventory, save and resume, weather |
| Mika Nolte | 71772 | bedroom, toy chest, advent calendar |

## Demo

**Play in the browser (alone): https://laraglueck.github.io/Merry-Scary-Christmas/**

The browser version is for **one player** (a web page may not open the network port that
playing together needs). The **three-player game** runs in the Godot version on laptops in
the same Wi-Fi or on one phone hotspot (see *Run the game* and *Play with three windows*).

## Run the game

1. Install **Godot 4.7.2** (standard version, not .NET) from [godotengine.org](https://godotengine.org/download).
2. Clone this repository.
3. Let Godot import the pictures and sounds once (needed before the first run and before the tests):

   ```bash
   godot --headless --path godot --import
   ```

4. Start the game:

   ```bash
   godot --path godot
   ```

   Or open `godot/project.godot` in the Godot editor and press ▶ (F5).

On a Mac, `godot` is `/Applications/Godot.app/Contents/MacOS/Godot`.

### Play alone

In the lobby type your name and click **Play alone**, then **Start game**. You choose one
hero; the order for the fuse box is on a note by the doll on the stairs.

### Play with three windows (one laptop)

To try the three-player game on one computer, open three windows:

- In the editor: **Debug → Customize Run Instances… → Enable Multiple Instances: 3**, then ▶.
- Or in a terminal, three times: `godot --path godot`

In one window click **Create room** and note the 4-letter code; in the other two type the
code and click **Join**. The host types a team name, then **Start game**.

### Test start (for trying the rooms quickly)

```bash
godot --path godot -- test
```

Starts the game with all three fuses already on and 30 minutes on the clock. Without the
word `test` nothing changes.

## Run the tests

```bash
godot --headless --path godot --script res://tests/run_tests.gd
```

All tests are in `godot/tests/` (one file per part, e.g. `test_bathroom_rules.gd`). The last
line says how many passed, for example `552 passed, 0 failed`. Import the assets once first
(step 3 above).

## Update the browser version

The folder `web/` is the game exported for the browser. After a change to the game, export
it again and commit the folder; when `main` changes, GitHub Pages puts it online
(`.github/workflows/pages.yml`).

1. Once: in the Godot editor, **Editor → Manage Export Templates → Download and Install**
   (the official templates for 4.7.2).
2. Export:

   ```bash
   godot --headless --path godot --export-release "Web" ../web/index.html
   ```

3. Try it locally:

   ```bash
   python3 -m http.server 8060 --directory web
   ```

   and open http://localhost:8060.

One-time setup by the repository owner: **Settings → Pages → Source: GitHub Actions**.

## How it is built

The full tour for the walkthrough (where the data is, what the tests cover, limits, how it
could change) is in [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md).

- **Godot 4.7, GDScript.** Every screen is a scene in `godot/scenes/` with its script in
  `godot/scripts/`.
- **Rules apart from screens.** Each puzzle's rules are pure functions in
  `godot/scripts/rules/` (no screens, no network), so they are easy to test: first check,
  then change, and a refused action changes nothing.
- **One shared game.** The host keeps the whole game in one dictionary and sends it to the
  other two players after every action (Godot's high-level multiplayer, `scripts/net/`).
  Players join with a 4-letter room code on the same Wi-Fi.
- **Specs first.** Every feature has a short spec in `specs/` (what, why, done when), then
  tests, then the code.
- **External data.** The living room window shows the real weather in Nuuk, Greenland, from
  [Open-Meteo](https://open-meteo.com/) (free, no key). If it does not answer within a few
  seconds, the window shows a frosted fallback, so the game never waits for it.
- **Leaderboard.** The fastest wins (team name, ending, time left) are stored online in a
  [Supabase](https://supabase.com/) table when it is set up (see *Online leaderboard*),
  otherwise in a file on the computer. If Supabase does not answer within 4 seconds, the
  local list is shown. The table only accepts sensible rows (name 1-20 letters,
  merry/scary, 0-3600 seconds).
- **Save and resume.** The host saves after every action; after a restart the lobby offers
  **Resume**.
- **Security.** No accounts or passwords, and no keys in the repository. Players only send
  actions; the host's rules check every action before anything changes. Rows from the
  online leaderboard are checked before they are shown.

### Online leaderboard (optional)

Without this the leaderboard is kept on the computer. To share it online, put the
project's address and its public (publishable) key in a file `supabase.cfg` in Godot's
user folder (on a Mac: `~/Library/Application Support/Godot/app_userdata/Merry Scary Christmas/`):

```ini
[supabase]
url="https://YOUR-PROJECT.supabase.co"
key="YOUR-PUBLISHABLE-KEY"
```

Or set the environment variables `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Never put the
secret (service role) key anywhere in the game.

## Project structure

```text
godot/
  scenes/          one scene per screen (hall, bathroom, attic, ...)
  scripts/         the screens' scripts
  scripts/rules/   the game rules (pure functions, tested)
  scripts/net/     network: rooms, joining, sending the shared game
  tests/           all tests and the test runner
  tools/           helper scripts for the pictures (add_image, cut_photo, ...)
  assets/          pictures and sounds, with CREDITS.md
specs/             one short spec per feature
docs/              walkthrough, team guide and asset brief
web/               the game exported for the browser (GitHub Pages)
```

## Credits

Every picture and sound with its source and licence is listed in
[godot/assets/CREDITS.md](godot/assets/CREDITS.md). Pictures were generated with AI from our
own prompts or drawn by our own tools; sounds are free to use (Pixabay and similar) or made
by us.
