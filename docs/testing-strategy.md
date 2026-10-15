# Testing Strategy

## Pinned engine and automated smoke tests

The initial project baseline uses **Godot 4.7.2-stable**. CI uses the same exact version as the checked-in project configuration. Update the CI pin, project note, and this section together when upgrading the engine.

The GitHub Actions workflow performs these checks:
1. Imports editor resources in headless editor mode.
2. Launches the configured main menu scene and verifies the gameplay scene can still be loaded headlessly.
3. Runs M1 vertical-slice checks for movement, interaction, HUD feedback, and localization.
4. Runs M2 vehicle checks for all three configurations, driver/input ownership, throttle, braking, steering, collision feedback, recovery, safe exit, and HUD state.
5. Runs M3 district checks for day/night lighting, pedestrian/traffic routes, population bounds, right-of-way, obstruction recovery, and world boundaries.
6. Runs M4 wanted/police checks for crime severity, detection, pursuit/search, occlusion, decay, and state clearing.
7. Runs M4 combat checks for weapon input, rate/ammo/reload, damage, police attacks, player death, wanted reset, and respawn.
8. Runs M5 progression checks for purchases, duplicate transactions/rewards, three-mission sequencing, first-aid consumption, vehicle repair, save round-trip including world time, numeric/range validation, and backup recovery.
9. Runs M6 UI-flow checks for save availability, overwrite confirmation, language/settings persistence, keyboard remapping/conflicts/reset, standard gamepad mappings and UI navigation, independent controller camera sensitivity/invert-Y persistence, UI-scale and high-contrast HUD accessibility persistence, live contrast updates, pause/resume, pause-menu mission restart, and display/audio preferences.
10. Checks required documents and changed-line whitespace.
11. Builds Windows Desktop and Linux/X11 packages using pinned Godot 4.7.2 export templates, validates the commit-bound build manifest, launches both exported binaries headlessly on their respective runners, and uploads each artifact with a run guide, acceptance checklist, asset/license inventory, and Godot license notice. This does not replace a clean-machine interactive playthrough.

These checks verify project loading and selected contracts. They do not prove visual quality, feel, export success, or target-machine performance.

## Test layers

### Static and project checks

- Validate project configuration and resource references.
- Parse scripts and load scenes in headless Godot.
- Check formatting and repository policy.
- Ensure required documentation and license inventory are present.

### Unit tests

Cover pure logic and state transitions:
- economy transactions and duplicate rewards
- mission prerequisites and objective completion
- wanted-level transitions
- save schema validation and migration
- weapon damage and invalid target handling

### Integration tests

- player movement and camera input, interactable raycast discovery, and interaction feedback
- world collision and boundary recovery
- vehicle interaction raycast and entry/exit handoff across sedan, compact coupe, and pickup
- distinct vehicle tuning, physical braking deceleration, and steering path change
- single-driver ownership and input ownership
- throttle, reverse, steering, braking, and recovery checks
- vehicle collision feedback, recovery clearance, upright reset, and safe exit positioning
- deterministic day/night lighting and sky-state changes, pedestrian route progression and alert response, crossing progress beside a stationary traffic body, bounded agent population, traffic route progression, junction yielding and bounded timeout under a stalled cross-traffic agent, on/off-screen physical stall recovery, and district-boundary checks
- crime event severity and wanted-level transitions
- police detection, pursuit, occlusion/search, reacquisition, decay, and explicit wanted clearing
- weapon raycasts, damage application, rate-of-fire, ammunition/reload, and aim state
- NPC death, police attack conditions, player incapacitation, wanted reset, and respawn
- mission completion grants one reward exactly once
- police detection creates and clears a pursuit correctly
- save/load restores progression and world time after relaunch; invalid day-time values are rejected and corrupt primary recovery uses the last known-good backup

### Acceptance tests

Run a scripted critical path:
1. Start a new game.
2. Explore the district, inspect the information board, and observe pedestrian/traffic behaviour.
3. Enter each of the sedan, compact coupe, and utility pickup, then drive, steer, brake, collide with a test obstacle, recover, and exit.
4. After gameplay controls are stable, manually compare steering response, braking distance, suspension, camera placement, collision handling, and recovery across the three prototypes.
5. Complete mission one and collect its reward.
6. Purchase an item or service.
7. Complete the remaining missions.
8. Save and quit.
9. Relaunch and verify mission/economy state.
10. Finish the final mission and reach the completion state.

### Manual test passes

- 15-minute living-district soak test with fixed agent counts, route progress, junction yielding, and no systemic traffic deadlock. Run locally with `godot --headless --path . res://tests/living_district_soak.tscn` or dispatch GitHub Actions with `run_living_district_soak` enabled.

- main-menu Continue availability, new-game confirmation/cancel, settings persistence, pause/resume, and no gameplay processing while paused
- keyboard binding changes across relaunch, duplicate-key rejection, reset-to-default, and Escape cancellation
- gamepad movement axes, combat/interaction buttons, pause/back, and UI focus navigation mappings
- controller camera sensitivity bounds, persistent invert-Y preference, and independent mouse/controller sensitivity
- run exported Windows build on a clean Windows machine; a CI export alone does not satisfy this manual acceptance check
- keyboard/mouse and supported controller
- camera clipping and inaccessible geometry
- vehicle steering, braking, suspension, collisions, and safe exit clearance
- NPC/traffic stuck recovery
- audio stream generation and independent master/music/effects settings in CI; listen to ambient music, UI feedback, weapon fire, hits, and vehicle impacts on a real audio device
- resolution changes and graphics settings
- performance in dense and quiet areas

## Test environment

Pin the Godot version and test on a documented desktop environment. Keep automated checks deterministic; isolate random seeds where appropriate. Record OS, CPU, GPU, driver, resolution, and renderer for performance runs.

## Defect severity

- P0: data loss, security/licensing issue, release cannot launch
- P1: crash, softlock, mission blocker, broken save/load, unusable controls
- P2: major gameplay defect with workaround
- P3: minor visual/audio defect or polish issue

## Release gate

No open P0/P1 defects. Required automated tests pass. The critical path succeeds in the packaged build. Known P2/P3 defects are documented and accepted explicitly.
