# Spec 30: Single player, names, free hero choice, powers, chest hint, leaderboard

Owner: Gloria (with changes in the lobby and network (Mathies), the character selection
(Leon) and the bedroom rules (Mika); each is tagged in the pull request)

## Why
The graders will probably play alone, but the game needed exactly three players. The
figures had no purpose, heroes were handed out instead of chosen, the chest stumped
players, and the professor suggested a high-score table (the course wiki names "scores"
as stored data and lists keyless APIs).

## What
- **Name:** before "Start game" the host types a team name (alone: their own name). It is
  stored in the game (`team_name`) and shown on the leaderboard.
- **Single player:** "Play alone" in the lobby. No room and no network: the computer is
  the host with one player (`network.play_alone`, `solo`). One hero is chosen. In the
  hall there is ONE wire order, on a note by the doll on the stairs; the right order
  switches on all three fuses together (`FuseRules.try_fuse_alone`). The mission card
  says "You are on your own tonight". Rooms work as they are.
- **Free hero choice:** nobody gets a hero by themselves; each player clicks one. A taken
  hero is greyed out and free again when its player picks another. "Next" only after
  choosing.
- **Hero powers**, once per game, shown on the cards and under the chosen hero, and as a
  button under the clock in the game (`power_rules.gd`, action `use_power`):
  Santa "Ho ho hint" (what to do next: the tip depends on the room and what is still
  unsolved), Snowman "Freeze" (+30 s on the clock), Nutcracker "Crack" (one part of the
  room's answer).
- **Help in three levels:** gentle hints in the rooms (the dust on the mirror, the
  calendar) stay; a power is the shortcut whenever the team wants; a rescue hint (almost
  the answer) comes only after `Settings.RESCUE_TRIES` (5) wrong tries: the fuse box names
  whose order it is, and the chest says "a mirror shows everything the wrong way round".
- **Leaderboard** on the end screen: the ten fastest wins (name, time left, ending). The
  host saves a win once. Stored in a Supabase table when `SUPABASE_URL` and
  `SUPABASE_ANON_KEY` are set (or `user://supabase.cfg`), never in the repository;
  otherwise, and whenever Supabase does not answer within 4 s, in a file on the computer.
  Rows from outside are checked (name 1-20 letters, merry/scary, 0-3600 s).
- **Christmas countdown** under the leaderboard: "Only 33 days until Christmas Eve!"
  (text may change).

## Out of scope
Cookies (next pull request), walking to objects, separate rooms per player.

## Done when
New tests (red first): single player in the network, lobby and hall; the name; free
choice and the power texts; the power rules and button; the chest hint; the leaderboard
rules and end screen; the countdown. All tests pass; the tests never touch the real
leaderboard or the internet.
