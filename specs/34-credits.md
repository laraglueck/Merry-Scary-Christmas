# Spec 34: Credits screen

Owner: Leon

## Why
The game should say who made it, like every game does after its ending.

## What
- Every end screen (Merry, Scary, Midnight) has a "Credits" button at the bottom left.
- A click opens a dark screen over the ending: the game name, "Made by", the five team
  members with their student numbers (from the README's team table, in the same order),
  and "Nova SBE · Introduction to Programming · Fall 2026".
- "Close" (or a click anywhere) goes back to the end screen.
- The team only: no list of sounds, pictures or tools (those stay in `assets/CREDITS.md`).
- The names live in `Settings.TEAM`, so they can be changed in one place.

## Done when
New tests (red first): the button on all three endings, the five names and numbers on the
credits screen, closing it, and that the button covers nothing. All tests pass.
