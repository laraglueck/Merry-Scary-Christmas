# Demo plan

Our plan for the live demo, following the course guide *Preparing the demo*. The demo runs
at the public URL; the three-player game is shown live on laptops.

**Public URL:** https://laraglueck.github.io/Merry-Scary-Christmas/

## 1. What we show, in this order

| # | What | Where | Shows |
| --- | --- | --- | --- |
| 1 | Open the URL, the story (skip with a click), title, **Play alone**, name, choose a hero | browser, projector | the app runs at its URL; story and art |
| 2 | Hall: mission card, the doll's note, fuse box (one **wrong** order first, then the right one) | browser | a refused action and its message; the lights come on |
| 3 | Living room: the window (live weather in Nuuk), the cookies, the clock | browser | the external API; the inventory |
| 4 | Use the hero's power (Santa's **Ho ho hint**) | browser | the powers; the hint box |
| 5 | Three players: one laptop **Create room**, two **Join** with the code, each picks a hero | 3 laptops, one network or phone hotspot | multiplayer, the host as referee |
| 6 | An ending and the **leaderboard** (fastest escapes) | laptop (online list) | stored data, the end screen |

A whole game takes too long for the demo: for step 6 use a game that is almost finished
(save it the day before and **Resume** it), or show the end screen of a quick test game.

## 2. Who does what

| Role | Member |
| --- | --- |
| Operates the browser demo (projector) | _to fill in_ |
| Host laptop (Create room) | _to fill in_ |
| Player laptops (Join) | _to fill in_, _to fill in_ |
| Speaks: story and rooms | _to fill in_ |
| Speaks: how it is built (see `docs/WALKTHROUGH.md`) | _to fill in_ |

At least two members can operate the demo, in case one is absent or a laptop fails.

## 3. What the demo depends on, and what happens if it fails

| Dependency | What could go wrong | What the game shows / our fallback | Check |
| --- | --- | --- | --- |
| **GitHub Pages** (the URL) | old version online; not deployed | nothing: then we play the Godot version on the laptop | *Actions* tab green after the last merge; open the URL before our turn |
| **Supabase** (online leaderboard) | free project paused after a week; no internet | after 4 s the game shows the local list on this computer; nothing breaks | open the Supabase dashboard the day before |
| **Open-Meteo** (weather in the window) | service down, slow, no internet | after 4 s a frosted window with "it snows anyway"; costs no game time | try once with Wi-Fi off |
| **Local network** (3 players) | eduroam blocks laptops from each other; room code not found | use one phone's hotspot; type the host's address instead of the code (README) | test the three laptops on the hotspot the day before |
| **Sound** | projector has no sound | subtitles show the story | — |
| **Secrets** | a key visible on the projector | close the Supabase dashboard and `supabase.cfg` | before sharing the screen |

No accounts, no passwords and no AI models: nothing to log in to and no daily quota.

The **browser version** keeps its own local leaderboard (it has no key), so the online list
is shown in the Godot version on a laptop.

## 4. Checklists

**The week before**
- [ ] Everything we show is merged to `main` and live at the URL.
- [ ] The whole demo runs once at the **URL** (not only on a laptop), in the order above.
- [ ] Starting data: the leaderboard has meaningful rows (remove test rows like "test" in the
      Supabase dashboard if we want a clean list).
- [ ] Failures tried on purpose: wrong fuse order, wrong clock time, invalid room code, an
      empty name (Start stays greyed out), Wi-Fi off for the weather.
- [ ] Tests pass on `main`, and everyone can say what they cover and what they do not
      (`docs/WALKTHROUGH.md`).
- [ ] Repository: public; README has the URL, members, run and test commands; no keys.

**The day before**
- [ ] One full rehearsal at the URL with the member who operates it.
- [ ] Supabase dashboard opened: the project is not paused.
- [ ] Three laptops tested together on the phone hotspot.
- [ ] A nearly finished game saved for step 6.
- [ ] Stop merging.

**On the day**
- [ ] Open the URL before our turn (the game loads about 50 MB the first time).
- [ ] One browser window, only the demo tab; dashboards, `supabase.cfg` and the agent closed.
- [ ] Hotspot on; the two player laptops ready in the lobby.
- [ ] If something fails: say what happened, show the fallback, continue.
