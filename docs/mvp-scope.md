# MVP Scope and Acceptance Criteria

## Scope rule

The items below are required scope, not a claim that they are implemented. If a requirement must change, document the reason, impact, and replacement acceptance criteria before removing it.

## Required capabilities

### World
- One connected, walkable and drivable fictional coastal-city district.
- Clearly readable roads, sidewalks, building blocks, landmarks, and a coastal or beach area.
- Collision coverage for traversable geometry and reliable world boundaries.
- Basic day/night variation via a shared world clock and environment lighting controller. Basic weather is included only after lighting and exposure remain stable.

**Acceptance:** the player can navigate the complete MVP area without falling through geometry, reaching unintended voids, or encountering a progression-blocking dead end.

### Player
- Third-person movement, walking, running, jumping, camera orbit, collision, interaction prompt, health, death, and respawn.
- Input remapping and sensitivity settings where supported by the selected input architecture.

**Acceptance:** movement and camera behave consistently at the target frame rate and after respawn; input does not remain stuck after UI transitions.

### Vehicles
- At least three distinct vehicle configurations built on a shared vehicle interface.
- Enter/exit, acceleration, braking, steering, reverse, collision response, and recovery from a stuck or overturned state.
- Vehicle state is safely handed back to the player on exit.

**Acceptance:** each vehicle can be entered, driven around a defined test route, collided with, exited, and reused without duplicate player instances or broken input ownership.

### NPCs and traffic
- Pedestrians follow navigation routes and respond to nearby events with a limited state machine.
- Vehicles follow authored road paths and avoid obvious permanent deadlocks.
- Off-screen simulation is simplified to maintain performance.

**Acceptance:** a repeatable test scene runs for at least 15 minutes without mass NPC accumulation, unbounded spawning, or systemic traffic deadlock.

### Police and wanted system
- Defined wanted levels, crime/event triggers, detection, pursuit, loss of line of sight, search, and decay/clear conditions.
- Debug visualization or logs for wanted-state transitions during development.

**Acceptance:** scripted scenarios cover each transition, including player death, vehicle changes, occlusion, and save/load policy.

### Combat
- A limited original weapon set; aiming, firing, hit detection, damage, ammo or cooldown rules, NPC death, player damage, and respawn.
- Violence is implemented as gameplay, without using protected GTA-specific animations, sounds, or assets.

**Acceptance:** hit results are deterministic enough for tests; invalid targets and out-of-range hits are handled safely.

### Missions
- At least three connected missions with objectives, mission state, success/failure, rewards, and replay or restart behaviour.
- Mission definitions are data-driven where practical; mission scripts do not directly manipulate unrelated systems.

**Acceptance:** all missions can be completed in a clean save, failed and restarted where designed, and completed progress persists after relaunch.

### Economy and interaction
- Persistent currency and at least a small set of purchasable items or services.
- Transactions validate affordability and cannot produce negative balances or duplicate rewards.

**Acceptance:** automated tests cover insufficient funds, successful purchase, repeated interaction, and reload.

### Save/load
- Versioned save schema for player progression, money, mission state, and selected world state.
- Atomic or recoverable writes where practical, validation on load, and a safe fallback for corrupt or older saves.

**Acceptance:** round-trip tests preserve required fields; corrupt data does not crash startup or overwrite a valid backup silently.

### UI and audio
- Main menu, pause menu, settings, HUD, mission notifications, and completion/failure feedback.
- Original or appropriately licensed sound effects and music.
- Localization-ready UI; user-facing language support is a separate content layer, not hard-coded into game logic.

**Acceptance:** UI remains navigable with keyboard/controller as scoped, does not trap input, and all critical game states have clear feedback.

### Release
- Exported desktop build, clean-machine smoke test, installation/run instructions, known-issues list, and asset-license inventory.

**Acceptance:** a tester can launch the packaged build without the Godot editor and complete the documented critical path.

## Explicit exclusions
- Online services, multiplayer, cloud saves, large-scale procedural city generation, full destructibility, complete state-sized world, and extensive cinematic campaign.
- Any feature removed from required scope must be recorded as an approved scope change.

## Release blockers
- Crash, softlock, unrecoverable save corruption, mission progression blocker, broken controls, unlicensed asset, or critical performance failure.
