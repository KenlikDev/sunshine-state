# Roadmap

Estimates are planning ranges, not delivery promises. Re-estimate after the first vertical slice and after each milestone.

| Milestone | Planned work | Exit gate | Status |
|---|---|---|---|
| M0 — Foundation | Repository conventions, scope, architecture, CI baseline | Foundation review and scope approval | Prepared for review |
| M1 — Vertical slice | Third-person controller, camera, greybox district, interaction, bilingual HUD | Automated checks and repeatable exploration test pass | Automated gate passed; manual review pending |
| M2 — Vehicles | Shared vehicle interface, sedan/compact/pickup prototypes, collision response and recovery | Automated driving, collision, recovery tests pass; manual handling review remains | Prototype gate passed; manual review pending |
| M3 — Living district | Authored pedestrian routes, player-alert state, road traffic routes, junction yield and bounded population | 15-minute stability test passes | In progress |
| M4 — Wanted and combat | Authoritative wanted state, police pursuit/search, single-weapon combat, damage and player respawn | Scripted wanted/combat scenarios pass; manual combat review complete | Wanted/police and combat prototypes implemented; regression review in progress |
| M5 — Missions and persistence | Three connected missions, economy, versioned save/load and backup recovery | Full critical path passes after reload; failure/restart and corrupt-save tests pass | Mission/economy/save foundations in regression testing |
| M6 — Presentation | Main menu, pause/settings flow, original Blender assets, lighting, UI, and audio | UI-flow checks pass; manual UX/art/audio review and performance capture remain | Menu/settings prototype in regression review; original art/audio not started |
| M7 — Release candidate | Regression, export, clean-machine test, documentation | No P0/P1 defects; acceptance checklist signed off | Not started |

## Dependency rule

Do not build advanced systems on top of unstable interfaces. Vehicle, mission, and save interfaces must be reviewed before dependent features proliferate.

## Implementation gate

The current branch contains an intermediate vehicle prototype, not the complete MVP. At least three vehicle configurations and all remaining required capabilities in `docs/mvp-scope.md` must be implemented and validated before calling the game an MVP or asking for the final MVP acceptance review.
