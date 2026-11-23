# Spec 17: Back to the lobby after the end

Owner: Mathies

## Why
Spec 16 (Gloria) ends the game with an end screen (Merry, Scary, Midnight). Its
"Back to the lobby" button was still hidden: the network had no way to end a finished game
for everyone. Without it, the team has to restart the app for a second round.

## What
- `network.gd`, host only:
  - `can_end_game() -> bool`: true for the host when the game is over (phase is not `"hall"`).
    A running game cannot be ended this way.
  - `end_game()`: the host clears the finished game and sends the empty game to everyone.
    Everyone is back in the lobby; the room stays open, so all three can start again at once.
- End screen (`ending.gd`, spec 16): the host sees "Back to the lobby"; Players 2 and 3 see
  "Waiting for Player 1..." instead. Started on its own (no network), neither shows.
- The midnight message uses the villain's new name from spec 16: "Midnight! Scary Jingles is
  awake. The team has lost."

## Change after manual test (18.11., Mathies)
- "Back to the lobby" is a red button (bigger, white text), so it is clear you can click it.

## Out of scope
Leaving the room from the end screen, a new room code, keeping statistics of past rounds.

## Done when
- The new tests in `test_network.gd` and `test_main.gd` were red first and are green; all
  older tests stay green.
- Manual: three windows play until midnight (`GAME_SECONDS` briefly 40), the host clicks
  "Back to the lobby", all three are in the lobby, "Start game" starts a new round at 10:00.
