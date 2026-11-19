# Spec 26: The living room window, with the real weather in Nuuk (Greenland)

Owner: Mathies (one click area in Lara's living room, the view itself in its own files)

## Why
Plan, "Muss" 8: something real in the game, with a fallback if the service does not answer.
Full test round (19.11.): a click on the window should show the outside. The elf lives in
Greenland (as people in Denmark and Greenland tell it, Santa lives there too), so the window
shows the real weather in Nuuk right now.

## What
- `settings.gd`: `WEATHER_PLACE := "Nuuk, Greenland"`, latitude 64.18, longitude -51.69,
  `WEATHER_TIMEOUT_SECONDS := 4.0`.
- `godot/scripts/rules/weather_rules.gd` (pure):
  - `url()`: Open-Meteo (free, no key), current temperature and weather code for Nuuk.
  - `from_response(text) -> Dictionary`: `{"ok", "kind", "temperature", "text"}`. Kinds from the
    WMO weather code: clear (0, 1), cloudy (2, 3), fog (45, 48), rain (51 to 67, 80 to 82), snow
    (71 to 77, 85, 86), storm (95 to 99). Text e.g. "Nuuk, Greenland, tonight: -8 °C, snow."
    (temperature rounded).
  - Anything broken (no answer, not JSON, missing values) gives `fallback()`: kind snow,
    "The glass is too frosted to read the thermometer." The game never stops because of it.
- Living room: a click area `WindowButton` on the window (`Rect2(44, 18, 160, 345)` on the stage),
  gold frame and hand on hover, hint "Look out of the window".
- A click opens `WindowView` (`window_view.gd`): the front garden seen through the window
  (`view_window_garden.png`, a window frame with bars on top), the weather as
  particles (snow, rain) or mist (cloudy, fog), and two lines:
  `WeatherLine` (the weather text) and `StoryLine`: "Somewhere out there, Santa's sleigh is
  flying tonight. Without Jingles." While waiting: "Wiping the frost off the glass...".
- The view asks Open-Meteo once per opening (`HTTPRequest`, 4 s timeout). Not in the headless
  tests: there it shows the fallback, and the tests feed it answers directly.
- Esc, Enter or a click closes the view. Only on this device; no time, nothing changes.

- After the manual test (19.11.): the moon lies on top of the lamp and the house. Now it is in the
  sky, behind the trees: `tools/make_window_view.gd` cuts the garden (`Rect2(0, 150, 620, 457)` of
  `room_garden.webp`) and paints `prop_moon_full.png` only where the picture is sky (blue), with a
  faint glow; branches and snowflakes stay in front. Result: `view_window_garden.png`.
- Second manual test (19.11.): "Wiping the frost off the glass..." was gone too fast. Now the glass
  starts frosted and the frost is wiped off from left to right with a soft edge, in
  `Settings.WINDOW_WIPE_SECONDS` (2.5 s); only then the weather shows (an answer that came earlier
  waits). The moon still covered thin branches: the tool now also counts dark pixels as "in front".
- Third manual test (19.11.): rain and storm did not look like it, and the full moon shone through
  clouds. Now: rain falls in slanted streaks (`WeatherRain` with a line picture, pointing the way it
  falls) under a darker sky (`WeatherTint`); a storm drives dense snow sideways (`WeatherStorm`,
  wind as gravity to the right) under a darker sky; for cloudy, fog, rain and storm the garden
  picture is `view_window_garden_cloudy.png` with a pale moon (the tool makes both pictures).
- Fourth manual test (19.11.): rain and storm keep the bright moon, like snow (only cloudy and fog
  use the pale one). "Without him" sounded like Santa: now "Without Jingles."

## Out of scope
Showing the weather anywhere else, a sleigh crossing the moon (needs a new picture), the
weather changing the puzzles.

## Done when
- `tests/test_weather_rules.gd` and the new tests in `test_living_room_screen.gd` were red first
  and are green; all other tests stay green.
- Manual: with internet the window shows today's weather in Nuuk; without internet the fallback.
