# Spec 34: German and Portuguese

Owner: Leon

## Why
Our team is German and studies in Lisbon, and not every player is at home in English.
Playing in your own language makes the riddles fairer and the story stronger.

## What
- **Three languages:** English, Deutsch, Português (European Portuguese). The picker is at
  the top right of the title: "English · Deutsch · Português", the chosen one in gold.
- **Only for this device:** every player chooses for themselves, so a team can play in
  three languages at once. The choice is remembered for the next start
  (`user://language.cfg`); the first time it is English.
- **English stays the source.** All code, rules, saved games and tests stay English. Godot
  translates every label, button, tooltip and placeholder when it is shown
  (`scripts/lang.gd`, auto translate).
- **Messages from the rules** ("Player 2: wrong order, -10 s") are built by the host in
  English and translated on each device: a template with `%s` / `%d` matches the message,
  and its parts are translated one by one ("Player 2" -> "Spieler 2" / "Jogador 2"). A
  translation may change the order of the parts with `%1$s`, `%2$s`.
- **The texts:** `scripts/translations/de.gd` and `pt.gd` (English -> translation). A text
  without a translation stays English, so a new text never breaks the game.
- **Riddles stay solvable:** every clue points to the same answer in every language.
- Not translated: the game name, "Scary Jingles", the ending titles "Merry Christmas!" and
  "Scary Christmas!", the English voice of the story (its subtitles are translated), texts
  inside pictures.

## Out of scope
More languages (adding one = one more file in `scripts/translations/` and one line in
`Lang.LANGUAGES`), a voice-over in German or Portuguese.

## Done when
New tests (red first): a text, a rule message part by part, parts in another order, every
translation keeps its `%s`/`%d`, the language switches and is remembered, the picker on the
title. All tests pass (they run in English). Manual: screenshots of the hall, a room and the
ending in German and Portuguese.
