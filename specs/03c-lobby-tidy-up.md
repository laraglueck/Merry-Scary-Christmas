# Spec 03c: Lobby tidy-up

Owner: Mathies

## Why
Manual test (17.11.): the lobby looks like a test screen. The status line repeats the room
code, the counter with +1 was only a network test, the code field runs across the whole width.

## What
- While the host's room is open, the status line is hidden: the big room code says it all.
  Errors and messages (e.g. "not a valid room code", "The host left the room") still show.
- The counter and its "+1" button are gone from the lobby (the network keeps them, its tests too).
- The code field is bigger (taller, larger letters) and not as wide as the screen; "Join" sits
  next to it.
- "Join" has its own colour (green), so it stands apart from "Create room".
- "Create room" is as wide as the code field and "Join" together. The room code and the
  players line only show once there is a room (no empty gap, no "nobody yet").

## Out of scope
New artwork for the lobby, removing the counter from network.gd.

## Done when
- The new and changed tests in `tests/test_lobby.gd` were red first and are green; all other
  tests stay green.
- A rendered screenshot at 1152 x 648 looks tidy.
