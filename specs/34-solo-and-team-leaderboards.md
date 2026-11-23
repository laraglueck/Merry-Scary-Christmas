# Spec 34: Separate leaderboards for solo players and teams

Owner: Leon

## Why
One player has to solve all three rooms alone, a team of three splits them up. Both have the
same 20 minutes, so their times cannot be compared fairly on one list.

## What
- Every win is saved with a `mode`: `"solo"` (played alone) or `"team"` (three players).
- The end screen shows only the list of its own mode: "Fastest escapes: Solo" or
  "Fastest escapes: Team", each with its own top 10.
- The time stays 20 minutes for both.
- Rows without a mode (saved before this change) count as team wins.
- Online: the Supabase table gets a `mode` column (`supabase/leaderboard_mode.sql`, run once
  in the SQL Editor before the new version is used). Until then the game falls back to the
  local list, as for any online error.

## Out of scope
Showing both lists at once, a different time for solo players.

## Done when
New tests (red first): a win's entry has its mode; a row with a strange mode is left out, one
without a mode counts as team; the top 10 is per mode; the end screen of a solo win shows the
solo list without team wins, and the other way round. All tests pass.
