# Sunshine State

Sunshine State is an original, single-player, third-person open-world crime-action game built with Godot 4 and Blender. The project is developed in focused milestones with documented interfaces, automated checks, and owner-controlled merges.

## Project status

**Review branch:** `codex/integrated-review-candidate`

**Status:** consolidated playable greybox prototype integrating milestones M1–M9. This branch is a single review entry point for the current work. It is **not yet accepted as the complete MVP or a production release**.

The branch contains a controllable third-person character, a bounded greybox coastal district, a day/night lighting cycle, an information board, an English/Russian HUD, three drivable vehicle prototypes (sedan, compact coupe, and utility pickup), four route-following pedestrians, four background traffic agents, an initial wanted/police loop, one raycast-based sidearm, health/damage and respawn, three connected missions, an economy and recoverable save/load, main and pause menus, persistent settings, accessibility controls, procedural audio, mission waypoints, and vehicle-health persistence.

### Open acceptance gates

- Complete an interactive playthrough on a clean Windows machine using the exported build, not the editor.
- Verify the critical path end to end: new game, driving and vehicle recovery, police/wanted behaviour, combat and respawn, all missions, economy interactions, save/load, and Continue after restarting the application.
- Run the 15-minute living-district stability soak against the final integrated candidate; results from a separate earlier validation branch are useful evidence but do not replace this gate.
- Review driving feel, traffic/pedestrian behaviour, UI layout at target display sizes, gamepad controls, accessibility, and the music/effects mix.
- Complete the final asset/license audit and triage any critical or progression-blocking issues.
- Review the persistence boundary: progression and selected world data plus vehicle health are saved, but vehicle transforms/velocities, NPC transforms, and a complete world snapshot are not currently persisted.

The full scope and measurable acceptance criteria remain in [docs/mvp-scope.md](docs/mvp-scope.md). Do not describe the project as an accepted complete MVP until the required gates have passed or any scope change has been explicitly approved and documented.

## Run locally

1. Install [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Clone this repository or download the ZIP for the `codex/integrated-review-candidate` branch, then open `project.godot` in Godot.
3. Run the project from the editor (F5); the main menu opens first. Starting a new game asks for confirmation when a valid save exists; Continue retains access to the existing save.

## Controls

- W A S D: move on foot; accelerate/reverse and steer while driving
- Left Shift: sprint
- Space: jump on foot; brake in a vehicle
- Mouse: orbit the active camera
- E: interact, enter a vehicle, or exit the current vehicle
- R: recover the current vehicle if blocked or overturned
- Left mouse button: fire; right mouse button: aim; T: reload; H: use a first-aid kit
- Escape: open/resume the pause menu; the mouse is recaptured when gameplay resumes
- F5: save progress; F9: load progress; F8: restart an active/failed mission (also available in the pause menu)
- F6: toggle English/Russian UI language (saved in settings); Settings includes keyboard remapping with conflict checks and reset defaults
- Controller: left stick move/drive; right stick camera; camera sensitivity and Y inversion configurable in Settings; L3 sprint; A jump/brake; X interact; LB aim; RB fire; Y recover vehicle; D-pad right reload; R3 first-aid kit; B pause/back

## Documentation

- [Game vision](docs/vision.md)
- [MVP scope and acceptance criteria](docs/mvp-scope.md)
- [Architecture](docs/architecture.md)
- [Gameplay systems](docs/gameplay-systems.md)
- [Vertical slice and controls](docs/vertical-slice.md)
- [Vehicle system and controls](docs/vehicle-system.md)
- [Living district simulation](docs/living-district.md)
- [Day-night environment cycle](docs/day-night-cycle.md)
- [Wanted and police system](docs/wanted-system.md)
- [Combat and damage system](docs/combat-system.md)
- [Missions, economy, and persistence](docs/progression-system.md)
- [Main menu, pause flow, and settings](docs/ui-flow.md)
- [Art and asset pipeline](docs/art-pipeline.md)
- [Asset and license inventory](docs/asset-license-inventory.md)
- [Testing strategy](docs/testing-strategy.md)
- [Performance budgets](docs/performance-budgets.md)
- [Desktop export and release smoke tests](docs/release-builds.md)
- [Release acceptance checklist](docs/release-acceptance-checklist.md)
- [Build manifest schema](docs/release-manifest.md)
- [Source register](docs/source-register.md)
- [Roadmap](docs/roadmap.md)
- [Branching and contribution workflow](docs/development-workflow.md)
- [Architecture decision records](docs/adr/README.md)

## Development principles

- Source code, identifiers, comments, and developer documentation are in English.
- Player-facing text is stored separately in translation resources; English and Russian are supported by the current HUD.
- Build in small, verifiable increments; never claim an unrun test passed.
- Develop on isolated `codex/*` branches. The repository owner controls `main`, `develop`, and all merges.
- Use original or appropriately licensed assets only.

## Validation

The latest full automated CI run on the parent M9 commit passed Godot import/startup, gameplay regression suites, documentation checks, and Linux/Windows export/runtime smoke checks. This is automated evidence, not a clean-machine interactive playthrough. The open acceptance gates above still apply to this integrated review candidate.
