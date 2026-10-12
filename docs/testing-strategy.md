# Testing Strategy

## Pinned engine and automated smoke tests

The initial project baseline uses **Godot 4.7.2-stable**. CI uses the same exact version as the checked-in project configuration. Update the CI pin, project note, and this section together when upgrading the engine.

The GitHub Actions workflow performs these checks:
1. Imports editor resources in headless editor mode.
2. Launches the configured main scene headlessly and exits after a short run.
3. Runs the M1 vertical-slice regression scene for bootstrap composition, movement, interaction, and Russian localization.
4. Runs the M2 vehicle regression scene for vehicle discovery, driver ownership, throttle movement, exit state restoration, and feedback.
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
- vehicle interaction raycast and entry/exit handoff
- single-driver ownership and input ownership
- throttle, reverse, steering, braking, and recovery checks
- vehicle collision and safe exit positioning
- mission completion grants one reward exactly once
- police detection creates and clears a pursuit correctly
- save/load restores progression after restart

### Acceptance tests

Run a scripted critical path:
1. Start a new game.
2. Explore the district and inspect the information board.
3. Enter the prototype sedan, drive, steer, brake, and exit.
4. Drive and test each required vehicle configuration after they are implemented.
5. Complete mission one and collect its reward.
6. Purchase an item or service.
7. Complete the remaining missions.
8. Save and quit.
9. Relaunch and verify mission/economy state.
10. Finish the final mission and reach the completion state.

### Manual test passes

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
