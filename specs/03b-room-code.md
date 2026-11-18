# Spec 03b: Room code

Owner: Mathies

## Why
The must list says "room code": players should type 4 letters, not an IP address.

## What
- `godot/scripts/net/room_code.gd` (pure): `make_code(rng)` gives 4 letters from
  A-Z without I and O (easy to read aloud); `is_valid_code(text)` accepts lower case
  and spaces around; `announce_message(code, port)` and `parse_announce(text)` build
  and read the message "MSC1|KRTW|47411" (anything else -> empty result).
- `network.gd`:
  - `host_room` also creates a room code, shows it in the status and announces
    "MSC1|code|port" every 0.5 s on the Wi-Fi (broadcast) and on this computer
    (127.0.0.1), UDP port 47412.
  - `join(text)`: an address -> join directly (plan B, as in spec 03); a room code ->
    listen for the matching announcement and join that host; no match within 5 s ->
    "Room KRTW not found"; anything else -> "Not a valid room code or address".
  - When the host leaves, it stops announcing (the code is not found any more).
- Lobby: one field for "room code or address", a big "Room code: KRTW" label for the host.

Spec change: the lobby's error text for bad input is now
"Not a valid room code or address" (the field accepts codes too).

## Out of scope
Rooms over the internet, several windows searching at the very same moment on one
computer (join one after another), reconnecting.

## Done when
- `tests/test_room_code.gd`, new tests in `tests/test_network.gd` and `tests/test_lobby.gd`
  were red first and are green; all older tests stay green.
- Manual: 3 windows on one Mac join with the code; then a second real device.
