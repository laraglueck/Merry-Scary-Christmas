# Spec 04: Fuse puzzle over the network

Owner: Mathies

## Why
The core of the demo: three devices, each player solves their own fuse with the
help of a teammate who sees the torn label.

## What
- `godot/scripts/rules/game_rules.gd`: the shared game. `new_game(rng)` returns one
  Dictionary `{phase: "hall", puzzle, penalty_seconds: 0, last_event: ""}`.
  `apply(game, player, action, data)` changes it for one player's action.
  Action "try_fuse" with `{wires}`: the player's own fuse (player i = fuse i) via
  `try_fuse`; right -> event "Player 2 turned on the green fuse. The bathroom is lit!",
  wrong -> penalty +10 and event "Player 1: wrong order, -10 s", invalid -> event with
  the reason, no penalty. Unknown actions change nothing.
  Team: rooms, attic and timer add their data and actions here.
- `network.gd`: `game` (only the host changes it, everyone gets a copy);
  `can_start()` true only for the host with 3 players and no game yet;
  `start_game()` creates the game and sends it to all; `send_action(action, data)`
  goes to the host, the host applies it and sends the new game to all.
  Nothing happens before the start. When the host leaves, the game is gone for the others.
- `godot/scenes/main.tscn` + `main.gd`: keeps the network and shows the screen for the
  phase: lobby before the game, hall when the game started, lobby again when the host left.
- Lobby: "Start game" button, only visible for the host, enabled with 3 players.
- Hall online (when it gets a network with a game): no player switch; shows only the own
  player's fuse and the label this player can see; clicks go to the host as "try_fuse";
  lamps, penalty and the last event come from the shared game.
  Without a network the hall works on one screen as before (spec 02).

## Out of scope
Players leaving or joining during the game, hiding the answer from devices
(each device has the whole puzzle), the clock, rooms, attic.

## Done when
- `tests/test_game_rules.gd`, `tests/test_main.gd` and the new tests in
  `test_network.gd`, `test_lobby.gd`, `test_hall.gd` were red first and are green;
  all older tests stay green.
- Manual: 3 windows play the fuse puzzle through main.tscn with room code and start button.
