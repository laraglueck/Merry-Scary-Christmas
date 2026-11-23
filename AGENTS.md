# Rules for coding agents (and for us)

## Secrets
- Secrets are never written in the code and never committed. The game reads the online
  leaderboard's settings from the environment variables `SUPABASE_URL` and
  `SUPABASE_ANON_KEY`, or from `supabase.cfg` in Godot's user folder (outside the
  repository). `supabase.cfg.example` shows the format with placeholder values.
- Only the public (publishable) key is used by the game. The secret (service role) key and
  the database password are never used, pasted into a chat, or written into any file here.
- Before a commit that touches settings or keys, check that the secrets file is ignored by
  git (`git check-ignore -v supabase.cfg`) and that no key is in the diff.
- If a key reaches GitHub, even for a moment: revoke it in the Supabase dashboard, make a
  new one, and tell the team. Deleting the commit is not enough.

## Working together
- Work on a branch; pull requests go into `godot-setup`, and `godot-setup` into `main`.
  Never commit directly to `main`.
- Every feature has a short spec in `specs/`; tests come first (red, then green).
  Run all tests before a commit:
  `godot --headless --path godot --script res://tests/run_tests.gd`
- No copyrighted pictures, characters or music; every asset is listed in
  `godot/assets/CREDITS.md`.
- After a change to the game, export the browser version again (see README,
  *Update the browser version*).
