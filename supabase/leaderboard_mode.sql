-- Spec 34: separate leaderboards for solo players and teams.
-- Run once in the Supabase dashboard (SQL Editor), BEFORE the new game version is used.
-- Wins saved before this change have no mode; they become team wins (the default).
-- No keys or passwords here (see AGENTS.md).

alter table leaderboard
  add column mode text not null default 'team' check (mode in ('solo', 'team'));
