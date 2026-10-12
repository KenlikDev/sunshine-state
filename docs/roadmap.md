# Roadmap

Estimates are planning ranges, not delivery promises. Re-estimate after the first vertical slice and after each milestone.

| Milestone | Planned work | Exit gate | Status |
|---|---|---|---|
| M0 — Foundation | Repository conventions, scope, architecture, CI baseline | Foundation review and scope approval | Prepared for review |
| M1 — Vertical slice | Third-person controller, camera, greybox district, interaction, bilingual HUD | Automated checks and repeatable exploration test pass | In progress |
| M2 — Vehicles | Shared vehicle interface, one polished vehicle, then two variants | Enter/drive/exit/recovery tests pass | Not started |
| M3 — Living district | Modular environment, pedestrian and traffic simulation | 15-minute stability test passes | Not started |
| M4 — Wanted and combat | Weapon/damage loop, detection, pursuit, search/clear | Scripted wanted scenarios pass | Not started |
| M5 — Missions and persistence | Three connected missions, economy, save/load | Full critical path passes after reload | Not started |
| M6 — Presentation | Original Blender assets, lighting, UI, audio | Art/UX review and performance capture pass | Not started |
| M7 — Release candidate | Regression, export, clean-machine test, documentation | No P0/P1 defects; acceptance checklist signed off | Not started |

## Dependency rule

Do not build advanced systems on top of unstable interfaces. Vehicle, mission, and save interfaces must be reviewed before dependent features proliferate.

## Implementation gate

The current vertical slice is an intermediate milestone, not the complete MVP. The remaining required capabilities in docs/mvp-scope.md must be implemented and validated before calling the game an MVP or asking for the final MVP acceptance review.
