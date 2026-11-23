# Security

## Scope

The game supports solo play and multiplayer on a trusted local network.
The host manages the shared game state; clients send action requests.

The host is trusted. Room codes help discover rooms on the local network;
they are not passwords or account authentication.

## Access controls

Code reviewed: `godot/scripts/net/network.gd`.

- The host derives each player's index from the sending connection.
- Action RPCs do not accept a client-supplied player-index argument.
- The host ignores actions from peers not registered in the room.
- Game-state updates use Godot's authority-only RPC configuration.
- The host processes actions through the game rules.

Code inspection and automated tests are separate forms of evidence.
These checks do not establish resistance to every possible malicious packet.

## Targeted security tests

File: `godot/tests/test_network_security.gd`.

| Test | Behaviour checked |
|------|-------------------|
| `test_unknown_sender_cannot_change_the_game` | An unregistered sender cannot change the game or trigger an update. This directly tests the host handler. |
| `test_client_identity_fields_do_not_override_connection` | A real client request containing false identity fields still acts on that client's own fuse, not the host's fuse. |
| `test_unknown_action_does_not_change_game` | An unknown action leaves the game unchanged. |
| `test_invalid_movement_types_do_not_change_game` | Selected string, array, null and boolean movement inputs leave the game unchanged. |
| `test_invalid_clock_types_do_not_change_puzzle` | Selected invalid clock input types leave the puzzle unchanged, cause no penalty and produce an error message. |

The input-validation tests call the game rules directly.
They cover these specific cases, not all actions, values or message sizes.

## Other test evidence

In `godot/tests/test_network.gd`:

- `test_fourth_device_is_rejected`
- `test_invalid_address_is_rejected`
- `test_invalid_input_is_rejected`
- `test_actions_before_start_do_nothing`
- `test_player_action_is_decided_by_host_and_shared`
- `test_only_the_host_counts_the_time_and_everyone_sees_it`

In `godot/tests/test_scary_ending_presents.gd`:

- `test_lock_in_requires_all_three_presents` checks all seven incomplete
  present combinations, even with the key.
- `test_lock_in_succeeds_with_key_and_all_presents` checks the valid ending.

The present-requirement tests exercise game rules directly, not malicious packets.

## Latest local test run

On 23 November 2026, Lara ran the full local suite:
557 passed, 0 failed.

This includes the five targeted security tests.
It applies to that local checkout, not automatically to main or the web export.

## Running the tests

From the godot directory, replace godot with your executable path if needed:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
```

## Dependency review

Repository inventory reviewed on 23 November 2026 at godot-setup commit
8248fb7c5f93e0c791548cf7430a841b9d27708f.
The new security tests were run separately in Lara's local checkout.

- The README specifies Godot Standard 4.7.2. Editor and export templates
  should use matching versions. Installation versions are not enforced.
- No addons directory, GDExtension descriptors or .NET project manifests
  were found in the reviewed repository tree.
- The optional Supabase leaderboard uses Godot's built-in HTTP API,
  without an installed Supabase SDK.
- Open-Meteo is an external weather service, not an installed package.
- Streamlit belongs to the separate placeholder page, not the Godot game.
  Root requirements.txt specifies streamlit>=1.40,<2.
- GitHub Pages workflow actions use major-version tags, not immutable SHAs.

### Python vulnerability check

Audit output: [python-audit.json](docs/security/python-audit.json). 

On 23 November 2026, pip-audit 2.10.1 resolved the root Streamlit requirement
in an isolated Python 3.12 Linux environment and checked 33 packages
using its PyPI vulnerability service.

Streamlit resolved to 1.67.0. No known vulnerabilities were reported
for that resolution.

This was not a scan of packages installed on team computers or in a
deployment. Different platforms, Python versions and future resolutions
can differ. Root requirements.txt still uses a version range.

### Godot advisory check

The official Godot 4.7.2 release notes and maintainer advisory page were
consulted on 23 November 2026. The advisory page listed no published advisories.

Sources:

- https://godotengine.org/article/maintenance-release-godot-4-7-2/
- https://github.com/godotengine/godot/security/advisories

This is not proof that Godot or its bundled libraries are vulnerability-free.
The Python package audit does not cover Godot binaries or WebAssembly exports.

## Security boundaries 

The host and local network are trusted; room codes are not passwords.
Tests cover the documented cases, not all malformed inputs or network attacks.
The Python audit covers the resolved package versions, not Godot binaries
or the deployed Supabase configuration.