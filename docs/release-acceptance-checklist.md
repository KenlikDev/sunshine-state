# Release Acceptance Checklist

This checklist is for a reviewer testing downloaded Windows/Linux development artifacts. Complete it against one exact commit SHA and record the environment. Passing CI is necessary, but does not replace these interactive checks.

## Test record

- Commit SHA:
- Artifact workflow run:
- OS version/build:
- CPU / RAM:
- GPU / driver:
- Renderer:
- Display resolution / scaling:
- Controller model and connection type (if tested):
- Tester / date:

## Launch and first-run behaviour

- [ ] Start the exported application without Godot installed.
- [ ] Confirm the main menu is visible and localized text is readable.
- [ ] Confirm Continue is disabled when no valid save exists.
- [ ] Start a new game and reach the district.
- [ ] With a valid save present, select New Game and cancel the confirmation; confirm active progression is unchanged.
- [ ] Re-select New Game and confirm; verify the game starts a clean session without silently deleting prior save files.
- [ ] Quit and relaunch the application without crashes or stuck background processes.

## Gameplay critical path

- [ ] Walk, sprint, jump, orbit the camera, interact, and cross the intended district boundaries.
- [ ] Inspect the district board and complete the first mission.
- [ ] Report property damage, verify wanted-state/police response, break line of sight, and observe search/decay behaviour.
- [ ] Purchase a first-aid kit, take damage, use the kit, and verify health/inventory are updated correctly.
- [ ] Complete the supply-run mission; verify reward and wallet values.
- [ ] Enter, drive, brake, reverse, steer, exit, collide, and recover each of the sedan, compact, and pickup prototypes.
- [ ] Damage a vehicle and use the service desk; verify the repair cost is charged once and the vehicle returns to full health.
- [ ] Observe day, night, and twilight lighting; verify road and interaction readability at each phase.
- [ ] Save, exit, relaunch, Continue, and verify mission/economy/wanted/world-time state is restored.
- [ ] Use a disposable test profile to corrupt a copied primary save and verify recovery from a valid backup; never corrupt a tester's only save.

## Controls, settings, accessibility and audio

- [ ] Navigate menus with keyboard and a supported controller.
- [ ] Rebind a key, attempt a conflicting key, cancel with Escape, reset defaults, and relaunch to confirm the expected mapping persists.
- [ ] Verify gamepad camera sensitivity and optional Y inversion.
- [ ] Test UI scale at 80%, 100%, and 140%; confirm text/buttons remain reachable and are not clipped.
- [ ] Enable high-contrast HUD; confirm objectives, interaction prompts, crosshair, combat, health and wanted status remain readable in bright and dark scenes.
- [ ] Test each resolution preset, windowed/fullscreen switching, and returning from settings.
- [ ] Verify master/music/effects sliders are independent and audibly change the intended output.
- [ ] Listen for clipping, clicks, harsh frequencies, excessive repetition, and level mismatches on a normal audio device.
- [ ] Test an actual supported controller on Windows and Linux if those platforms are intended for distribution.

## Stability and release blockers

- [ ] Complete a 15-minute district traversal/AI soak on the target build or confirm the matching commit has a successful automated soak run.
- [ ] No crashes, softlocks, progression blockers, unrecoverable save failures, stuck input, or systemic traffic deadlocks.
- [ ] Record all P0/P1 issues and verify none remain before release acceptance.
- [ ] Review the current asset-license inventory and match the Godot Engine notices to the exported runtime.
- [ ] Confirm the packaged guide, license notice, and known limitations are present.
- [ ] Document tested systems and retain logs/checklist with the release candidate.

## Current known limitations to consider

The current build remains a prototype. It includes a first CC0 low-poly art pass for characters, drivable/background vehicles, and core buildings, while roads, shoreline dressing, and four secondary building facades remain procedural/blockout geometry. The humanoid is a reusable base model, not a bespoke protagonist, and animation/art polish remains open. Audio is procedural and needs subjective mix review; vehicle damage state resets when the world is reconstructed; NPC/vehicle transforms are not in the save snapshot; weather, time-based schedules, installation UX, signing, and installer packaging are not complete. Do not sign off these items as complete merely because CI passes.
