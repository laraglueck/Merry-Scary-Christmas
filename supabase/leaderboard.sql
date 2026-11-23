-- The online leaderboard (spec 30): the table and its access rules in Supabase.
-- This is what was run once in the Supabase dashboard (SQL Editor). It is kept here so the
-- whole team can see and review it: a change made only in the dashboard is not in the
-- repository. To set up a new Supabase project, run this file once in the SQL Editor.
-- No keys or passwords here: those never go into the repository (see AGENTS.md).

create table leaderboard (
  id bigint generated always as identity primary key,
  -- Input validation in the database: only sensible rows are accepted.
  name text not null check (char_length(name) between 1 and 20),
  ending text not null check (ending in ('merry', 'scary')),
  seconds_left int not null check (seconds_left between 0 and 3600),
  created_at timestamptz default now()
);

-- Access control: Row Level Security on, and only two things allowed with the public key.
-- There is no rule for UPDATE or DELETE, so nobody can change or delete an entry.
alter table leaderboard enable row level security;
create policy "anyone can read" on leaderboard for select using (true);
create policy "anyone can add a win" on leaderboard for insert with check (true);
