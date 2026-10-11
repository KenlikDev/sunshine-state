# Roadmap

Estimates are planning ranges, not delivery promises. Re-estimate after the first vertical slice and after each milestone.

| Milestone | Planned work | Exit gate |
|---|---|---|
| M0 — Foundation | Repository, documentation, branch protections, pinned tools, CI skeleton | Project conventions reviewed and baseline checks pass |
| M1 — Vertical slice | Third-person controller, camera, greybox district, interaction | Repeatable exploration test passes |
| M2 — Vehicles | Shared vehicle interface, one polished vehicle, then two variants | Enter/drive/exit/recovery tests pass |
| M3 — Living district | Modular environment, pedestrian and traffic simulation | 15-minute stability test passes |
| M4 — Wanted and combat | Weapon/damage loop, detection, pursuit, search/clear | Scripted wanted scenarios pass |
| M5 — Missions and persistence | Three connected missions, economy, save/load | Full critical path passes after reload |
| M6 — Presentation | Original Blender assets, lighting, UI, audio | Art/UX review and performance capture pass |
| M7 — Release candidate | Regression, export, clean-machine test, documentation | No P0/P1 defects; acceptance checklist signed off |

## Dependency rule
Do not build advanced systems on top of unstable interfaces. Vehicle, mission, and save interfaces must be reviewed before dependent features proliferate.
