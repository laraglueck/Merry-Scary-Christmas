# Demo plan

Our plan for the live demo, following the course guide *Preparing the demo*: **two minutes
of demo, three minutes of questions.** The demo runs at the public URL; the three-player game
is shown live on laptops.

**Public URL:** https://laraglueck.github.io/Merry-Scary-Christmas/

## 1. What we show, in this order (2 minutes)

| Time | What | Where | Shows |
| --- | --- | --- | --- |
| 0:00 | The URL is already open on the title screen: one sentence on the story, the three languages, **Start**, **Play alone**, name, hero | browser, projector | the app runs at its URL; story, art, languages |
| 0:25 | Hall: the doll's note, the fuse box, one **wrong** order first ("−10 s", the screen shakes), then the right one | browser | a refused action and its message; the lights come on |
| 1:00 | Living room: look out of the **window** (live weather in Nuuk) | browser | the external API |
| 1:15 | The hero's power (Santa's **Ho ho hint**) | browser | the powers; the hint box |
| 1:25 | Switch to the prepared **three-player room**: three heroes in the hall, one player solves something, all three screens change | 3 laptops, one phone hotspot | multiplayer, the host as referee |
| 1:50 | Closing sentence with the pictures of the endings (README) | browser, projector | the two leaderboards, results card, the three endings |

A whole game takes about 20 minutes, so the attic and the endings are shown as screenshots
(`docs/screenshots/`). The bedroom chest cannot be opened first: its symbols come from the
bathroom.

**If time runs short:** leave out 1:15 (the power), never the window or the three players.

## 2. Roles

We agree on the roles before the demo: one operates the browser, one hosts the three-player
room, two join it, and everyone can answer questions (any of us may be asked about any part:
[WALKTHROUGH.md](WALKTHROUGH.md)). At least two of us can operate the demo, in case one is
absent or a laptop fails. The host's laptop should be one with the Supabase settings, because
only the host saves a win online.

## 3. What the demo depends on, and what happens if it fails

| Dependency | What could go wrong | What the game shows / our fallback | Check |
| --- | --- | --- | --- |
| **GitHub Pages** (the URL) | old version online; not deployed | nothing: then we play the Godot version on the laptop | *Actions* tab green after the last merge; open the URL before our turn |
| **Supabase** (online leaderboard) | free project paused after a week; no internet | after 4 s the game shows the local list on this computer; nothing breaks | open the Supabase dashboard the day before |
| **Open-Meteo** (weather in the window) | service down, slow, no internet | after 4 s a frosted window with "it snows anyway"; costs no game time | try once with Wi-Fi off |
| **Local network** (3 players) | eduroam blocks laptops from each other; room code not found | use one phone's hotspot; type the host's address instead of the code (README) | test the three laptops on the hotspot the day before |
| **Device** | someone opens the URL on a phone | phones are not supported (no on-screen keyboard); use a laptop | — |
| **Leaving the browser tab** | the game pauses and goes silent ("Paused while away") | click **Continue**; this is meant to happen | do not switch windows during the browser part |
| **Versions** | the three laptops have different versions | joining or playing can go wrong | all pull the newest `main` the day before |
| **Sound** | projector has no sound; the music button is off | subtitles show the story | play one sound before our turn |
| **Secrets** | a key visible on the projector | close the Supabase dashboard and `supabase.cfg` | before sharing the screen |

No accounts, no passwords and no AI models: nothing to log in to and no daily quota.

The **browser version** keeps its own local leaderboard (it has no key, on purpose), so the
online list is shown in the Godot version on a laptop.

## 4. Checklists

**The week before**
- [x] Everything is merged to `main` and live at the URL (23 November).
- [ ] The whole demo runs once at the **URL** (not only on a laptop), in the order above.
- [ ] Starting data: the leaderboard has meaningful rows (remove test rows like "test" in the
      Supabase dashboard if we want a clean list).
- [ ] Failures tried on purpose: wrong fuse order, wrong clock time, invalid room code, an
      empty name (Start stays greyed out), Wi-Fi off for the weather.
- [x] Tests pass on `main` (23 November).
- [ ] Everyone can say what the tests cover and what they do not (`docs/WALKTHROUGH.md`).
- [x] Repository: public; README has the URL, members, run and test commands; no keys
      (23 November).

**The day before**
- [ ] One full rehearsal at the URL with a clock: two minutes.
- [ ] Supabase dashboard opened: the project is not paused.
- [ ] Three laptops tested together on the phone hotspot.
- [ ] All laptops have the newest `main`.
- [ ] Stop merging.

**On the day**
- [ ] Open the URL before our turn and click through to the title screen (the first
      load is large, up to 85 MB).
- [ ] One browser window, only the demo tab; dashboards, `supabase.cfg` and the agent closed.
- [ ] Hotspot on; the three laptops already in the hall with their heroes.
- [ ] If something fails: say what happened, show the fallback, continue.
