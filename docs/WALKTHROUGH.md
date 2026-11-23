# Repository walkthrough

A guide for the walkthrough part of the presentation. The teaching staff opens the
repository and asks how the project is built, and **any of us can be asked about any
part**. So each of us should be able to answer everything on this page, not only our own
rooms. For each part: **what** it is, **why** we built it that way, its **limits**, and
**how it could change**.

## 1. The big picture in one minute

- **Godot 4.7, GDScript.** One Godot project in `godot/`. Each screen is a scene in
  `godot/scenes/`, and its script is in `godot/scripts/`.
- **Three layers:**
  1. **Rules** (`godot/scripts/rules/`) are pure functions with no screens, no network and no files.
     They decide what is allowed and what changes.
  2. **Network** (`godot/scripts/net/`) carries actions to the host and the game back to every player.
  3. **Screens** (`godot/scripts/*.gd`) only *show* the game and *send* clicks as actions.
- **One shared game:** the whole game is one Dictionary (`net.game`). Only the host
  changes it.
- **Specs, then tests, then code:** every feature has a short spec in `specs/` (why, what,
  done when). We wrote its tests first (red), then the code (green).

## 2. Follow one click (the best way to explain the whole app)

Example: a player clicks the plate of cookies in the living room.

1. **Screen:** `living_room.gd` → `net.send_action("take_cookies", {})`.
   The screen changes nothing itself.
2. **Network:** `network.gd` `send_action` → if this computer is not the host, the action
   goes to the host with an RPC (`_request_action`).
3. **Host:** `_host_apply` → `GameRules.apply(game, player, "take_cookies", {})`.
4. **Rules:** `game_rules.gd` `_take_cookies` **first checks** (is the room lit? is the team
   in it? are the cookies still there?), **then changes** (puts "cookies" into the inventory
   and writes `last_event`). If the check fails, nothing changes and the player only sees the reason.
5. **Host again:** saves the game (`save_game.gd`) and sends the new Dictionary to every
   player (`_receive_game`).
6. **All screens:** the signal `game_changed` → every screen redraws from `net.game`. The plate
   disappears and the cookies show in the inventory bar.

**Why like this?** There is one place that decides (no cheating, no two players disagreeing),
and the rules can be tested without starting any screen.

## 3. Where is what

| Question | Answer and file |
| --- | --- |
| Where does the game start? | `scenes/main.tscn` + `scripts/main.gd`: story → title → lobby → hero choice → hall/rooms → ending |
| Where are the puzzles' rules? | `scripts/rules/` one file per part: `fuse_rules`, `living_room_rules`, `bathroom_rules`, `bedroom_rules`, `attic_rules`, `photo_rules`, `clock_rules`, `inventory_rules`, `power_rules`, `walk_rules`, `leaderboard_rules`, `weather_rules`, `character_rules`; `game_rules.gd` puts them together (`new_game`, `apply`) |
| Where are numbers like the 20 minutes? | `scripts/settings.gd` (`GAME_SECONDS`, ports, items, heroes, rescue tries) |
| How do players connect? | `scripts/net/network.gd` (Godot high-level multiplayer, ENet, port 47411) and `room_code.gd` (4-letter code, found on the Wi-Fi via port 47412) |
| Playing alone? | `network.play_alone()`: the computer is host with one player, no network at all |
| Where is the data stored? | the running game in memory on the host (`net.game`); the **save** in `user://saved_game.save` on the host's computer; the **leaderboard** in a Supabase table online, or `user://leaderboard.json` locally |
| The database table? | `supabase/leaderboard.sql`: columns, checks and the two access rules |
| External API? | weather in Nuuk from **Open-Meteo** (`window_view.gd`, `weather_rules.gd`, no key) and **Supabase** for the leaderboard (`net/leaderboard.gd`) |
| Pictures and sounds? | `godot/assets/`, every source and licence in `assets/CREDITS.md`; helper scripts in `godot/tools/` |
| The browser version? | `web/` (Godot's Web export, preset in `godot/export_presets.cfg`), put online by `.github/workflows/pages.yml` (spec 32) |
| Tests? | `godot/tests/`, one file per part, runner `run_tests.gd` |

## 4. Questions the staff may ask

**Where is the data stored?**
The game itself is one Dictionary in the host's memory. After every action the host saves it
as a text file (`user://saved_game.save`, with `var_to_str` so the types stay right), so
**Resume** works after a crash. The leaderboard is stored in a Supabase table when it is
set up, otherwise in a local JSON file. Nothing is stored about the players except the name
they type.

**What do the tests cover, and what do they not cover?**
There are about 540 tests in `godot/tests/`. They cover:
- every rule with **accepted and refused** actions and edge cases (wrong code, twice, dark
  room, wrong player, too many tries → rescue hint)
- the screens: does the button exist, is it greyed out, what does a click send?
- the network with real host and players on this computer
- save and resume, the leaderboard rules (bad rows from outside are thrown away), and the
  weather (good answer, bad answer, no answer)

A test also fails if Godot reports an error while it runs, so a crash can never look green.
Tests use their own save and leaderboard files and never touch the internet.

They do **not** cover:
- how it looks (pictures, positions): we checked that by screenshots and play tests
- sound
- three real laptops on a real Wi-Fi
- the real Supabase and Open-Meteo servers

**What happens if the external API is unavailable?**
- **Weather:** after a few seconds without an answer the window shows a frosted fallback
  and it snows anyway. The game never waits for it, and it costs no time.
- **Supabase:** after 4 seconds (`TIMEOUT_SECONDS`), or on any error, the end screen shows
  the local list instead. Every win is always saved locally too.

**Why is the host the referee?**
If every player changed the game themselves, two players could change it at the same time
and disagree. With one referee there is one truth. Players only *ask* (send actions), so a
changed copy of the game cannot cheat.

**Why rules as pure functions?**
They are easy to test (put a Dictionary in, look at the Dictionary that comes out), and
every room owner could work in their own file without breaking the others.

**Security?**
- No accounts and no passwords.
- **No keys in the repository:** Supabase's URL and public key come from environment
  variables or `user://supabase.cfg`, which lies in Godot's user folder on each computer,
  outside the repository.
- The secret (service role) key is never used.
- **Lowest permissions (access control):** the game only has the public key, and
  Supabase's **Row Level Security** is switched on for the `leaderboard` table with exactly
  two rules: "anyone can read" (SELECT) and "anyone can add a win" (INSERT). There is no
  rule for UPDATE or DELETE, so with the public key nobody can change or delete an entry.
  (Checked in the Supabase dashboard: *Database → Policies*; the SQL is in
  `supabase/leaderboard.sql`.)
- Input is checked in two places: the host's rules check every action, and leaderboard
  rows from outside are checked (name 1-20 letters, merry/scary, 0-3600 s) both by the
  Supabase table and in the game.
- **The rules for secrets** are written down in `AGENTS.md`; `supabase.cfg.example` shows
  the format with placeholders, and the real `supabase.cfg` is in `.gitignore`. The Git
  history contains no key.
- **In the presentation:** close the Supabase dashboard and `supabase.cfg` before sharing
  the screen.

## 5. Limits (be honest; the top grade asks for them)

- **The browser version is for one player.** A web page may not open a network port, so
  Create room and Join are hidden there (`lobby.gd`, `in_browser`). The browser also has
  no emoji font (`web_text.gd`) and no key for the online leaderboard, so it keeps its
  own local list.
- **Laptop or computer only.** The URL opens on a phone, but the browser version opens no
  on-screen keyboard (so no name can be typed and the game cannot start) and walking needs
  W A S D. How it could change: switch on Godot's on-screen keyboard for the web export and
  add buttons for walking.
- **Multiplayer needs the same network.** Players find the host on the local Wi-Fi (or
  type the host's address). It does not work across the internet, and university Wi-Fi may
  block it, so the demo uses three windows on one laptop or **Play alone**.
- **The host is a single point of failure.** If the host quits, everyone is back in the
  lobby; only the host can resume the save.
- **The leaderboard trusts the host.** With the public key, someone could send a fake but
  valid-looking row. The table only blocks rows that make no sense.
- **The free Supabase project pauses** after a week without use. Then the online list is
  not reachable and the game shows the local list after 4 seconds (nothing breaks). Before
  the presentation, open the Supabase dashboard once to wake it up.
- **The puzzles are random within limits** (clock time, tap order, symbols, fuse orders),
  but the rooms and story are always the same.
- **Pictures** are fixed 1376 × 768 pictures; a very different window shape shows bars.

## 6. How it could change

- **Online play** over the internet, also in the browser: replace ENet with WebSockets
  through a server in the middle (or Supabase Realtime). The rules would not change at
  all, only `network.gd`.
- **A new room:** a scene + a rules file + an entry in `main.gd` `SCREENS` + actions in
  `game_rules.gd` `apply`.
- **Fair leaderboard:** let a small server (e.g. a Supabase Edge Function) check the
  finished game before it saves a row.
- **Settings** like time, tries and number of players are all in `settings.gd`, so they can
  be changed in one place.

## 7. Who built what (but everyone should know all of it)

| Part | Main person |
| --- | --- |
| Hall, fuse box, network, clock, inventory, save/resume, weather | Mathies |
| Living room, clock lock, rhyme | Lara |
| Bathroom, attic, endings, pictures, single player, powers, leaderboard, cookies | Gloria |
| Bedroom, toy chest, advent calendar | Mika |
| Story, title, heroes and accessories, walking, sounds, pause | Leon |
