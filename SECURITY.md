# Security

## Scope

This game supports solo play and multiplayer on a trusted local network.
The host manages the shared game state. Clients send action requests.

## Protections reviewed in the code

In `godot/scripts/net/network.gd`:

- The host derives each player's index from the sending peer's connection.
  Action requests do not accept a client-supplied player index.
- The host ignores action requests from peers that are not registered
  in the room.
- Game-state updates use Godot's authority-only RPC configuration.
- Game actions are processed through the host's game rules.

These observations come from code review. They are not a claim that
all possible network attacks have been tested.

## Existing automated tests

The following tests were reviewed for this document.
The latest local execution result is recorded below.

| Behaviour checked | Test file | Test name |
|-------------------|-----------|-----------|
| A fourth device is rejected from a full room | `godot/tests/test_network.gd` | `test_fourth_device_is_rejected` |
| An invalid IP address is rejected | `godot/tests/test_network.gd` | `test_invalid_address_is_rejected` |
| Invalid room-code/address input is rejected | `godot/tests/test_network.gd` | `test_invalid_input_is_rejected` |
| Actions before the game starts do not create a game | `godot/tests/test_network.gd` | `test_actions_before_start_do_nothing` |
| A client action is processed by the host and shared | `godot/tests/test_network.gd` | `test_player_action_is_decided_by_host_and_shared` |
| Client clock advancement does not advance game time | `godot/tests/test_network.gd` | `test_only_the_host_counts_the_time_and_everyone_sees_it` |
| Locking Jingles in is rejected for all seven incomplete present combinations, even with the key | `godot/tests/test_scary_ending_presents.gd` | `test_lock_in_requires_all_three_presents` |
| Locking Jingles in succeeds with the key and all three presents | `godot/tests/test_scary_ending_presents.gd` | `test_lock_in_succeeds_with_key_and_all_presents` |

The gift-requirement tests exercise game-rule validation directly.
They do not simulate malicious network packets.

## Latest local test run

On 23 November 2026, the full test suite completed locally:
552 passed, 0 failed.

This result applies to the local checkout tested on that date.
It does not establish that the same checks pass on main.

## Running the tests

From the `godot` directory, using the Godot executable installed
on your computer:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
```

## Security boundaries

The game is designed for a trusted local network.
The host is trusted and controls the shared game state.
Room codes help discover rooms; they are not passwords.

## Verification scope

This document covers the code and tests listed above.
It does not establish resistance to forged RPCs, network flooding,
or all malformed inputs. Repository-history credential scanning
and dependency vulnerability checks were not verified in this review.