# Testing Strategy

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
- player enter/exit vehicle
- vehicle collision and recovery
- mission completion grants one reward exactly once
- police detection creates and clears a pursuit correctly
- save/load restores progression after restart

### Acceptance tests
Run a scripted critical path:
1. Start a new game.
2. Complete mission one and collect its reward.
3. Purchase an item or service.
4. Complete the remaining missions.
5. Save and quit.
6. Relaunch and verify mission/economy state.
7. Finish the final mission and reach the completion state.

### Manual test passes
- keyboard/mouse and supported controller
- camera clipping and inaccessible geometry
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
No open P0/P1 defects. Required automated tests pass. Critical path succeeds in the packaged build. Known P2/P3 defects are documented and accepted explicitly.
