# Spec 03: Network base (lobby with a shared counter)

Owner: Mathies

## Why
Room code and 3 players are a must, and networking is our biggest risk.
First we prove that 3 devices can share one state, with a simple counter
instead of the game. If something fails, we know it is the network.

## What
`godot/scripts/net/network.gd` (a Node). One device hosts (= Player 1), up to two
more join (= Player 2, Player 3) with the host's address. The host decides
everything: other players only send requests, the host changes the state and
sends the new state to every player.

- `host_room(port)`: opens the room; status shows the host's Wi-Fi addresses.
- `join_room(address, port, timeout)`: invalid address -> "Not a valid address";
  no answer within the timeout (5 s) -> "Could not connect".
- A 4th device gets "Room is full" and stays unconnected; the others keep 3 players.
- `add_one()`: +1 on the shared counter, only when connected. The host changes it,
  everyone sees the same value.
- Host leaves -> the others see "The host left the room".
- Pure helpers: `lan_addresses(all)` keeps IPv4 addresses except 127.x and 169.254.x;
  `next_free_index(taken)` gives the lowest free player index 0..2, else -1.

`godot/scenes/lobby.tscn` + `godot/scripts/lobby.gd`: "Create room", address field +
"Join", status, player list ("Player 1 (you)"), counter + "+1" (only when connected).
"Create room" and "Join" are disabled while in a room or joining.

Port 47411, max 3 players and join timeout 5 s live in `settings.gd`.

## Out of scope
4-letter room code with automatic search on the Wi-Fi (spec 03b), reconnecting
after a lost connection, playing over the internet / itch.io, the fuse puzzle
over the network (spec 04).

## Done when
- `tests/test_network.gd` (host and players as separate "devices" in one test run,
  over 127.0.0.1) and `tests/test_lobby.gd` were red first and are green.
- Manual: 3 windows on one Mac (127.0.0.1), then 2 or 3 real devices on the same
  Wi-Fi or a phone hotspot.
