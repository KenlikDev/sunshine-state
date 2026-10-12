# Living District — M3

## Scope

M3 introduces a small, fixed population of background pedestrians and road traffic to exercise the city blockout. These are systems prototypes rather than final character models, traffic rules, or production navigation.

## Pedestrians

- Four pedestrian agents follow authored waypoint loops on sidewalks.
- Agents use a small state machine: `PATROL` and `ALERT`.
- When the player enters the alert radius, a pedestrian flees briefly, then returns to the patrol route when the alert timer expires.
- The initial implementation uses deterministic authored routes on the greybox map, not a baked NavMesh. Routes must be updated together with the road/sidewalk layout.

## Traffic

- Four traffic agents follow bounded north-south and east-west waypoint routes on the main crossroad.
- Vehicles use kinematic collision bodies for predictable background movement; the player-drivable vehicles remain physics-based `VehicleBody3D` scenes.
- East-west traffic yields near the central junction while north-south traffic is approaching or crossing.
- A forward obstacle ray causes an agent to wait; a sustained obstacle can trigger a short reverse-and-retry recovery.
- At route endpoints, agents reverse their waypoint direction rather than spawning replacements.

## Population and off-screen simulation

- The current population is fixed at four pedestrians and four traffic vehicles. No timer-based or proximity-based spawning is enabled.
- Distant agents use simpler movement updates and skip camera-proximity obstacle checks; agents near the camera or player use the full local behaviour.
- Population counts are tested across repeated physics updates. This is an early stability check, not a claim that the 15-minute acceptance test has been completed.

## Automated checks

The M3 regression scene checks:
- fixed agent counts and no population growth during the test window
- pedestrian route movement and alert-state response to a nearby player
- road-route movement and district bounds
- north-south right-of-way at the main junction

## Running the long-duration soak test

Run `godot --headless --path . res://tests/living_district_soak.tscn` from the project root to perform the default 15-minute run locally. The script checks population counts, route movement, district bounds, and prolonged agent stalls throughout the run.

GitHub Actions also exposes an opt-in manual workflow input named `run_living_district_soak`. Dispatch the `Repository checks` workflow with that input enabled to run the long-duration test on a pinned Godot 4.7.2 runner. The default push/PR workflow intentionally uses the shorter regression test instead.

## Remaining acceptance work

The MVP acceptance criterion still requires a repeatable 15-minute simulation run. The long-duration pass must record the Godot version, OS, CPU/GPU, renderer, and resolution, and confirm there is no NPC accumulation, unbounded spawning, or systemic traffic deadlock. Camera avoidance, path coverage, performance and interactions with player-driven vehicles also require manual testing.
