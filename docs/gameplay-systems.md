# Gameplay Systems Specification

## Player state
States include on-foot, entering vehicle, driving, exiting vehicle, incapacitated, and respawning. Transitions must be explicit and reject invalid double transitions.

## Interaction
Use a common interaction contract with eligibility check, prompt metadata, and execute action. Range and line-of-sight checks should be configurable. The prompt is presentation only; the interaction service validates the action again on execution.

## Vehicle state
Vehicle control should be owned by exactly one controller at a time. Entering a vehicle transfers input ownership only after the entry transition succeeds. Exiting checks clearance and uses a safe fallback if the nominal exit point is blocked.

## NPC state machine
Initial states: idle, travelling, reacting, fleeing, confronting, incapacitated. Keep transition causes observable in debug logs. NPCs must have despawn and stuck-recovery policies.

## Traffic
Represent road lanes as authored route graphs or spline paths with stop/turn metadata. Use a bounded spawn budget and collision-aware following. Avoid relying on general-purpose navigation meshes for all vehicle road behaviour.

## Crime and wanted
Crimes are typed events with severity, witness/detection context, and source entity. Wanted state is authoritative in one system. Police agents receive target/search tasks rather than independently modifying the wanted level.

## Combat
Separate weapon configuration, aiming presentation, hit query, damage application, and reaction. Define collision layers and masks centrally. Do not let client-side visual effects determine authoritative damage results.

## Missions
A mission is a state machine with stable ID, prerequisite conditions, ordered or parallel objectives, completion/failure rules, and reward transaction. Mission state changes must be testable without rendering a full cinematic sequence.

## Economy
All rewards and purchases pass through a transaction API. The API checks idempotency, balance, item validity, and duplicate reward prevention.

## Persistence
Only persistent data is serialized. Node paths and runtime object references are not save identifiers. Use stable IDs and migration functions when the schema changes.

## Debug support
Provide development-only overlays/logging for player state, vehicle state, NPC state, mission transitions, wanted level, active entity counts, and frame-time metrics.
