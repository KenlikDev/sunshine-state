# Testing Strategy

## Pinned engine and automated smoke tests

The initial project baseline uses **Godot 4.7.2-stable**. CI uses the same exact version as the checked-in project configuration. Update the CI pin, project note, and this section together when upgrading the engine.

The GitHub Actions workflow performs these checks:
1. Imports editor resources in headless editor mode.
2. Launches the configured main scene headlessly and exits after a short run.
3. Runs the M1 vertical-slice regression scene for bootstrap composition, movement, interaction, and Russian localization.
4. Runs the M2 vehicle regression scene for all three vehicle configurations, distinct power tuning, vehicle entry/driver ownership, throttle movement, braking deceleration, steering response, static-barrier collision, impact feedback, safe recovery, exit restoration, and HUD feedback.
5. Checks required documents and changed-line whitespace.

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
- pedestrian route progression, alert-state response, bounded agent population, traffic route progression, junction yielding, and district-boundary checks
- crime event severity and wanted-level transitions
- police detection, pursuit, occlusion/search, reacquisition, decay, and explicit wanted clearing
- weapon raycasts, damage application, rate-of-fire, ammunition/reload, and aim state
- NPC death, police attack conditions, player incapacitation, wanted reset, and respawn
- mission completion grants one reward exactly once
- police detection creates and clears a pursuit correctly
- save/load restores progression after restart; corrupt primary save recovery uses the last known-good backup

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

- main-menu Continue availability, settings persistence, pause/resume, and no gameplay processing while paused
- keyboard/mouse and supported controller
- camera clipping and inaccessible geometry
- vehicle steering, braking, suspension, collisions, and safe exit clearance
- NPC/traffic stuck recovery
- audio and UI feedback
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
