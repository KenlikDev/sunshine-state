# Sunshine State

Sunshine State is an original, single-player, third-person open-world crime-action game built with Godot 4 and Blender. The project is developed in focused milestones with documented interfaces, automated checks, and owner-controlled merges.

## Project status

**Current milestone:** M6 — main menu, pause flow, and persistent language, camera, display, and master-volume settings in regression review.

The current branch contains a controllable third-person character, a bounded greybox coastal district with a real-time day-night lighting cycle, an information board, an English/Russian HUD, three drivable vehicle prototypes (sedan, compact coupe, and utility pickup), four route-following pedestrians, four background traffic agents, and an initial wanted/police loop, one raycast-based sidearm, health/damage, automatic player respawn, and an initial three-mission/economy/save-load loop. This is an intermediate prototype, not the complete MVP.

The full MVP scope remains defined in [docs/mvp-scope.md](docs/mvp-scope.md). The three vehicle types are greybox prototypes and still need manual handling and visual review. Pedestrian and traffic agents are an early bounded simulation prototype; the required 15-minute stability test is not yet complete. The wanted/police loop covers crime reports, wanted levels, line-of-sight pursuit, searching and decay. The combat prototype covers one weapon, aiming, ammo/reload, damage, police attacks and player respawn; manual weapon feel, audio/animation and broader combat balance remain unfinished. Mission, economy and save/load foundations are now present but require regression and manual review. Final art, audio, world polish, and packaged release validation remain required.

## Run locally

1. Install [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Clone the repository and open `project.godot` in Godot.
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
- F5: save progress; F9: load progress; F8: restart an active/failed mission
- F6: toggle English/Russian UI language (saved in settings); Settings includes keyboard remapping with conflict checks and reset defaults

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
- [Testing strategy](docs/testing-strategy.md)
- [Performance budgets](docs/performance-budgets.md)
- [Desktop export and release smoke tests](docs/release-builds.md)
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

GitHub Actions runs Godot headless resource import, a main-scene smoke test, vertical-slice, vehicle-system, living-district, wanted-system, combat-system, progression-system, and UI-flow regression tests. An opt-in manual workflow runs the 15-minute living-district soak test; it has not yet been accepted as passed. Manual vehicle handling tests and export checks are still required; the game is not yet a packaged release build.
