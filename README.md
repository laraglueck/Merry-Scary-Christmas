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
the same Wi-Fi or on one phone hotspot (see *Play together* below).

## Run the game

The quickest way to play alone is the browser link above. To play **together**, or to run
the code yourself, use Godot. It takes about 10 minutes the first time.

### 1. Get Godot (once)

1. Download **Godot 4.7.2, standard version** (not ".NET") from
   [godotengine.org/download](https://godotengine.org/download). If a newer version is
   offered, take 4.7.2 from the [download archive](https://godotengine.org/download/archive/).
2. **Mac:** open the downloaded file and drag **Godot** into *Applications*.
   **Windows:** unzip it; the `.exe` inside is Godot (no installation needed).

### 2. Get the game (once)

- **Without Git:** on this GitHub page click the green **Code** button → **Download ZIP**,
  and unzip it.
- **With Git:** `git clone https://github.com/laraglueck/Merry-Scary-Christmas.git`

### 3. Start it

1. Open Godot. In the *Project Manager* click **Import**, choose the file
   `godot/project.godot` inside the game folder, and click **Import** (or **Import & Edit**).
2. The editor opens and imports the pictures and sounds (the first time this takes a
   minute).
3. Press **▶** at the top right (or **F5** / on a Mac **Cmd + B**). The game starts in its
   own window: the story (a click skips it), then **Start**, then the lobby.

From a terminal it works too (first import once, then start):

```bash
godot --headless --path godot --import
```

```bash
godot --path godot
```

`godot` is the Godot program: on a Mac `/Applications/Godot.app/Contents/MacOS/Godot`, on
Windows the path to the `.exe`.

### Play alone

In the lobby click **Play alone**, type your name and click **Start game**. You choose one
hero; the order for the fuse box is on a note by the doll on the stairs.

### Play together (three laptops)

Every laptop needs Godot and the game (steps 1 to 3 above). All three laptops must be in
**the same network**, for example:

- **the same Wi-Fi**, e.g. at home, or
- **one phone's hotspot** that all three join. Use this where the Wi-Fi does not let
  laptops talk to each other, which is often the case on university Wi-Fi (eduroam).

1. **Laptop 1 (the host, e.g. on the projector):** click **Create room**. A 4-letter room
   code appears. If the computer asks *"Allow incoming network connections?"* (Mac) or shows
   a firewall window (Windows), click **Allow**, otherwise the others cannot join.
2. **Laptops 2 and 3:** type the code and click **Join**.
3. **If the code is not found:** type the host's address instead of the code (four numbers
   with dots, e.g. `172.20.10.2`). On the host's Mac: *System Settings → Wi-Fi → Details*
   (IP address); on Windows: *Settings → Network → Properties* (IPv4 address).
4. When all three are in, the host types a team name and clicks **Start game**. Each player
   chooses a hero, then **Next**.

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
(open the project once in the editor, or run the import command above).

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
The file `supabase.cfg.example` shows the format; the real `supabase.cfg` is ignored by git
(`.gitignore`), and the rules for secrets are in [AGENTS.md](AGENTS.md).

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
