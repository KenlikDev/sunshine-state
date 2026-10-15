# Day–Night Environment Cycle

## Behaviour

The district owns a lightweight `DayNightCycle` controller that advances the game clock continuously. The default full-day duration is 900 seconds, starting at 09:30. The cycle drives the directional sunlight elevation, sunlight intensity/color, ambient illumination, and background sky color. Sunrise and sunset use a warm twilight palette; night uses lower blue ambient lighting and a dark sky.

The controller exposes `get_time_of_day()` and `set_time_of_day(hour)` so gameplay systems, tests, and future time-dependent activities can share one authoritative in-session clock. Tests can set noon or midnight directly without waiting for real time to pass.

The cycle is deterministic and deliberately small. When the world is active, SaveService writes `time_of_day_hours` into the optional world payload and restores it when loading either in gameplay or before a new gameplay scene is constructed. Existing schema-version-1 saves without this field remain valid and start the new scene at its default time. The cycle does not yet include a moon mesh, stars, volumetric atmosphere, weather, or exposure adaptation.

## Verification

The M3 living-district regression checks that the cycle exists, that it references the active environment and directional light, that midday illumination exceeds midnight illumination, and that the sky background changes between day and night. The M5 progression regression validates the saved clock range and verifies that backup recovery restores the prior saved time. The separate 15-minute soak test checks fixed populations, movement, district bounds, and prolonged agent stalls while the environment clock advances.

## Remaining presentation work

Final sky and lighting art direction, sunrise/sunset interpolation review on target hardware, day/night readability of roads and prompts, and weather are not complete. Basic day/night behaviour does not imply a final lighting pass.
