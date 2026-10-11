# Architecture

## Runtime structure

Use a small number of stable boundaries. Prefer composition and explicit interfaces over deep inheritance.

- **Bootstrap:** loads settings, save service, audio service, and the initial scene.
- **World:** owns district streaming boundaries, spawn points, navigation data, lighting, and world-level events.
- **Player:** owns movement and camera; delegates interaction, health, and equipment to components.
- **Vehicle:** owns vehicle physics and input state; exposes a shared enter/exit and driving interface.
- **NPC:** owns a small state machine and references navigation/interaction services.
- **Traffic:** manages road routes, spawn budgets, and despawning outside the active simulation area.
- **Wanted system:** consumes crime and detection events; owns wanted state and search/pursuit policy.
- **Mission director:** owns mission state transitions and objective evaluation; mission definitions are data.
- **Economy:** validates transactions and emits purchase/reward events.
- **Save service:** serializes versioned persistent state; gameplay systems expose explicit save data.
- **UI:** observes game state and sends commands; it should not be the authoritative owner of gameplay rules.

## Dependency rules

1. Gameplay systems must not depend on concrete UI scene nodes.
2. UI must call public commands or observe signals, not mutate arbitrary gameplay fields.
3. Mission scripts must use system APIs rather than reach into unrelated nodes.
4. Save data must be explicit, versioned, and independent of transient scene-tree references.
5. Avoid global singletons unless the service is truly application-wide and its lifetime is clear.
6. Prefer signals/events for cross-system notifications; avoid untraceable event chains.
7. Keep physics work inside appropriate physics callbacks and test state transitions independently.

## Proposed scene layout

- `scenes/bootstrap/`
- `scenes/world/`
- `scenes/player/`
- `scenes/vehicles/`
- `scenes/npc/`
- `scenes/missions/`
- `scenes/ui/`

## Proposed code layout

- `scripts/core/`
- `scripts/gameplay/`
- `scripts/ai/`
- `scripts/systems/`
- `scripts/ui/`
- `data/missions/`
- `data/vehicles/`
- `data/items/`

## Data contracts

- Mission definitions: stable mission ID, prerequisites, objectives, success/failure rules, rewards, and version.
- Vehicle definitions: stable ID, handling parameters, mass, traction tuning, visual asset reference, and supported interaction points.
- NPC definitions: archetype, movement profile, reaction profile, and spawn constraints.
- Save schema: schema version, timestamp, player state, mission state, economy state, and approved world-state fields.

## Performance architecture

Use distance-based simulation tiers:
- Near: full animation, navigation, interaction, and collision.
- Mid-range: reduced update rate and simplified decision logic.
- Far: lightweight route/state representation or despawn/recreate from stable data.

Do not implement complex off-screen simulation before profiling demonstrates a need.
