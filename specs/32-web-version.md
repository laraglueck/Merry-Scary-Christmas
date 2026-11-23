# Spec 32: The browser version

Owner: Gloria (small changes in the lobby (Mathies), the hall (Mathies), the clock bar
(main.gd) and the end screen; each is tagged in the pull request)

## Why
The course asks for the app to run at a deployed URL. Our game is a Godot program, so a
browser cannot run it as it is: Godot has to export it for the web first.

## What
- **Export:** `godot/export_presets.cfg` has a "Web" preset (no threads, so any simple
  host works). It writes the game to `web/` (`index.html`, `index.wasm`, `index.pck`, ...).
- **Online:** `.github/workflows/pages.yml` puts `web/` on GitHub Pages whenever `main`
  changes. (Vercel works too: root directory `web`, no build command.)
- **Only playing alone in the browser:** a web page may not open a network port, so there
  is no room to create or join. The lobby hides "Create room" and the code field, and says:
  "In the browser you play alone ... Playing together (3 players) works in the Godot version
  on one Wi-Fi: see the README." On the laptop nothing changes.
- **No emoji boxes:** the browser has no emoji font, so emojis are left out there
  (`web_text.gd`); the leaderboard arrow becomes ">".
- In the browser the save and the local leaderboard are kept by the browser itself; the
  weather works as on the laptop. The online leaderboard needs its key from a file on the
  computer, so the browser shows its own local list (no key is ever put in the export).

## Out of scope
Playing together in the browser (it would need a server on the internet in between).

## Done when
New tests (red first): the browser lobby (no room buttons, the note, playing alone works,
nothing changes on the laptop) and the emoji helper. All tests pass. The exported game was
played in a browser: story, title, lobby, hero, hall, saving and resuming.
