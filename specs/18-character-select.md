# Spec 18: Character selection

Owner: Leon

## Why
The three players have no figure yet. Before a game starts every player should choose one
of the three characters (Santa, snowman, nutcracker) and customise it with a scarf/jacket
colour (red, green, yellow). The pictures for all 9 combinations are already in
`godot/assets/images/` (`char_santa.png`, `char_santa_green.png`, ...).
Showing the figures in the house (spec 19) and walking around with them (spec 20) come later.

## What
- New phase `"select"` of the shared game: `{"phase": "select", "selection": {...}, "last_event": ""}`.
  `selection` maps the player index to `{"character", "colour", "accessory", "ready"}`.
- `scripts/rules/character_rules.gd` (pure functions, like `inventory_rules.gd`):
  - `pick(selection, player, character, colour) -> String`: sets the player's choice and
    resets "ready". Each character and each colour can only be taken by one player; a refused
    pick changes nothing and returns the reason.
  - `set_ready(selection, player) -> String`: needs a pick first.
  - `all_ready(selection) -> bool`: all `Settings.MAX_PLAYERS` players are ready.
  - `first_free_colour(selection, player) -> String`: default colour when a character is clicked.
  - `picture_file(character, colour) -> String`: `char_santa.png` for red, `char_santa_green.png` otherwise.
  - `final_characters(selection) -> Dictionary`: `{player: {"character", "colour"}}` for the game.
- `Settings.CHARACTERS` and `Settings.CHARACTER_COLOURS`: names and dot colours.
- `network.gd`:
  - `begin_selection()` (host, same conditions as `can_start()`): the game becomes the empty
    selection for everyone. The lobby's "Start game" calls it (after the "saved game will be
    lost" question, as before).
  - Actions `pick_character` (`character`, `colour`) and `ready` go through `send_action`; the
    host applies them in `GameRules.apply` (select phase).
  - When all three are ready the host starts the real game (`GameRules.new_game` with
    `"characters"`), as `start_game()` did: clock at 10:00, saved, sent to everyone.
  - A player who leaves during the selection loses their choice.
  - `can_end_game()` is false during the selection (it is not a finished game).
- Screen `scenes/character_select.tscn` + `scripts/character_select.gd` (layout after Leon's sketch):
  - same night scene as the title (`ui_title.webp`, snow, dark edges), title `SelectTitle`;
  - left, one below the other: the three figures `Card_santa`, `Card_snowman`, `Card_nutcracker`
    (small picture, name, who has it; a figure taken by another player is disabled);
  - middle, a little right of the screen's middle: the chosen figure big (`Picture_big`);
  - two pairs of arrows beside the figure: at head height `AccessoryPrev`/`AccessoryNext`
    (`AccessoryLabel`; a placeholder: only "None (coming soon)" until the pictures exist,
    `Settings.ACCESSORIES`), at hip height `ColourPrev`/`ColourNext` (`ColourLabel`, scarf; the
    nutcracker has a jacket); colours taken by others are skipped;
  - everybody starts with the first free figure and colour; clicking a card changes the figure
    and keeps colour and accessory;
  - `NextButton` ("Next") confirms; then `WaitLabel` ("Waiting for the others ...") and no more
    changes; `MessageLabel` shows the host's `last_event` (e.g. why a pick was refused);
  - without a network (⌘ R) a small switch "Player 1/2/3" plays all three locally.
- `selection` entries also hold `"accessory"` (default `"none"`); `final_characters` keeps it.
- `main.gd`: shows the screen for phase `"select"`; the menu music goes on during it.
- `GameRules.new_game(rng, characters := {})` stores `game["characters"]`.

## Out of scope
Showing the figures in the rooms (spec 19), moving them separately (spec 20), more colours or
characters, choosing again after the game started.

## Done when
- The new tests `tests/test_character_rules.gd`, `tests/test_character_select.gd` and the new
  ones in `test_network.gd`, `test_game_rules.gd`, `test_main.gd`, `test_lobby.gd` were red first
  and are green; all older tests stay green.
- Manual: three windows, "Start game" -> everyone sees the selection; a figure or colour taken by
  another player is blocked; when all are ready the game starts at 10:00.
