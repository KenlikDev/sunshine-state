# Roadmap

Estimates are planning ranges, not delivery promises. Re-estimate after the first vertical slice and after each milestone.

| Milestone | Planned work | Exit gate | Status |
|---|---|---|---|
| M0 — Foundation | Repository conventions, scope, architecture, CI baseline | Foundation review and scope approval | CI baseline operational; owner scope review remains open |
| M1 — Vertical slice | Third-person controller, camera, greybox district, interaction, bilingual HUD | Automated checks and repeatable exploration test pass | Automated gate passed; manual owner playthrough pending |
| M2 — Vehicles | Shared vehicle interface, sedan/compact/pickup prototypes, collision response and recovery | Automated driving, collision, recovery tests pass; manual handling review remains | Prototype gate passed; manual review pending |
| M3 — Living district | Authored pedestrian routes, player-alert state, road traffic routes, junction yield and bounded population | 15-minute stability test passes | Functional regression passes; isolated 15-minute stability run in progress |
| M4 — Wanted and combat | Authoritative wanted state, police pursuit/search, single-weapon combat, damage and player respawn | Scripted wanted/combat scenarios pass; manual combat review complete | Automated wanted/combat regression passes; balance and manual combat review pending |
| M5 — Missions and persistence | Three connected missions, economy, versioned save/load and backup recovery | Full critical path passes after reload; failure/restart and corrupt-save tests pass | Automated regression passes; owner critical-path playthrough pending |
| M6 — Presentation | Main menu, pause/settings flow, persistent language/mouse/gamepad-camera/display/audio/keyboard settings, gamepad controls, day/night lighting, original assets, UI, and audio | UI/export checks pass; manual controller/UX/art/audio review and performance capture remain | Main/pause/settings and procedural-audio prototypes pass CI; gamepad mappings covered in regression; original Blender art and final audio mix pending |
| M7 — Release candidate | Regression, desktop export, clean-machine test, documentation, asset/license inventory | No P0/P1 defects; acceptance checklist signed off | Windows/Linux export and CI gameplay smoke pass; clean-machine playthrough, final asset/license audit, signing, and packaging gates remain open |

## Dependency rule

Do not build advanced systems on top of unstable interfaces. Vehicle, mission, and save interfaces must be reviewed before dependent features proliferate.

## Implementation gate

The current branch contains an intermediate vehicle prototype, not the complete MVP. At least three vehicle configurations and all remaining required capabilities in `docs/mvp-scope.md` must be implemented and validated before calling the game an MVP or asking for the final MVP acceptance review.
