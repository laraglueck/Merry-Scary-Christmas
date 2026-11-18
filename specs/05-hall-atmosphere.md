# Spec 05: Hall atmosphere

Owner: Mathies

## Why
The demo should feel like a haunted house at night: the hall light flickers until
the team has restored the power, and the house plan shows which rooms are lit.

## What (in `hall.gd`, online and offline)
- A dark overlay over the whole hall flickers while not all fuses are on, like a loose
  bulb: a calm pause of 0.6 to 1.8 s, then a short burst of 2 to 4 quick dips
  (each at most 0.1 s), then calm again (`flicker_cycle(rng, strength)`).
  At most 30 % dark (changed after manual test 1: 45 % with ~3 dips per second
  looked too strong and unnatural).
  The flicker gets weaker with each fuse that is on
  (`flicker_strength(lit_count)`: highest with 0 fuses, 0 with all 3).
  With all 3 fuses on, the flicker stops and the overlay is fully clear.
- The overlay never blocks clicks.
- The house plan shows one tile per room: dark while its fuse is off, warm yellow
  once it is on (a short glow when it lights up). The room text stays ("... : lit").
- Maximum darkness and the pause length live in `settings.gd`.

## Out of scope
Artwork, sound, Santa pop-up.

## Done when
- New tests in `tests/test_hall.gd` were red first and are green, all older tests stay green.
- Manual: the hall flickers, gets calmer with each fuse, stops with all three; tiles light up.
