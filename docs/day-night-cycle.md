# Day–Night Environment Cycle

## Behaviour

The district owns a lightweight `DayNightCycle` controller that advances the game clock continuously. The default full-day duration is 900 seconds, starting at 09:30. The cycle drives the directional sunlight elevation, sunlight intensity/color, ambient illumination, and background sky color. Sunrise and sunset use a warm twilight palette; night uses lower blue ambient lighting and a dark sky.

The controller exposes `get_time_of_day()` and `set_time_of_day(hour)` so gameplay systems, tests, and future time-dependent activities can share one authoritative in-session clock. Tests can set noon or midnight directly without waiting for real time to pass.

The cycle is deterministic and deliberately small: it does not yet include a moon mesh, stars, volumetric atmosphere, weather, exposure adaptation, shadows tuned per time of day, or persisted world time across save/load.

## Verification

The M3 living-district regression checks that the cycle exists, that it references the active environment and directional light, that midday illumination exceeds midnight illumination, and that the sky background changes between day and night. The separate 15-minute soak test checks fixed populations, movement, district bounds, and prolonged agent stalls while the environment clock advances.

## Remaining presentation work

Final sky and lighting art direction, sunrise/sunset interpolation review on target hardware, day/night readability of roads and prompts, and weather are not complete. Basic day/night behaviour does not imply a final lighting pass.
