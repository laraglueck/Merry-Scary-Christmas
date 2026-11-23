# Spec 34: Results card on the end screen

Owner: Leon

## Why
After an ending the team only sees "Presents found" and the time. Players like to compare
how a game went and who did what, and to show it to others (a screenshot of the end screen).

## What
- A card on the end screen, top left (the leaderboard stays top right), in the same style
  as the leaderboard: "Your escape".
- Lines, from the shared game (`ResultsRules.lines(game)`, a pure function):
  - **Time left:** e.g. "Time left: 04:12" (Midnight: "Time left: 00:00").
  - **Mistakes:** how many wrong tries cost time and how much, e.g. "Mistakes: 3 (-60 s)".
    A power (Freeze) does not hide them.
  - **Powers used:** e.g. "Powers: Freeze (Player 2)", or "Powers: none".
  - **Who found what:** one line per item the team has, in the inventory's order,
    e.g. "Present 1: Player 1". The whole photo: who put it together.
- The game remembers this while it runs: `game["found_by"]` (item -> player, written by
  `InventoryRules.add`), `game["mistakes"]` and `game["mistake_seconds"]` (counted where a
  penalty is added). Old saved games without them still show the card (as far as known).

## Out of scope
Names per player (the game only knows "Player 1-3" and one team name), sharing as a picture.

## Done when
New tests (red first): who found an item is remembered; wrong tries are counted; the lines
for a full game, for a game with nothing found and for an old game without the new fields;
the card on all three end screens, not covering the leaderboard. All tests pass.
