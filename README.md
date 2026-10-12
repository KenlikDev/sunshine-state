# Sunshine State

Sunshine State is an original, single-player, third-person open-world crime-action game built with Godot 4 and Blender. The project is developed in focused milestones with documented interfaces, automated checks, and owner-controlled merges.

## Project status

**Current milestone:** M1 — first playable vertical slice in progress.

The current implementation branch introduces a controllable third-person character, a bounded greybox coastal district, one interactable information board, and an English/Russian HUD. This is an intermediate prototype, not the complete MVP.

The full MVP scope remains defined in [docs/mvp-scope.md](docs/mvp-scope.md). Vehicles, NPCs and traffic, wanted/police systems, combat, missions, economy, save/load, final art, audio, and packaged release validation are still required.

## Run locally

1. Install [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Clone the repository and open project.godot in Godot.
3. Run the project from the editor (F5).

## Controls

- W A S D: move
- Left Shift: sprint
- Space: jump
- Mouse: orbit the camera
- E: interact with the information board when the prompt appears
- Escape: release the cursor; click the game view to capture it again
- F6: toggle English/Russian UI language

## Documentation

- [Game vision](docs/vision.md)
- [MVP scope and acceptance criteria](docs/mvp-scope.md)
- [Architecture](docs/architecture.md)
- [Gameplay systems](docs/gameplay-systems.md)
- [Vertical slice and controls](docs/vertical-slice.md)
- [Art and asset pipeline](docs/art-pipeline.md)
- [Testing strategy](docs/testing-strategy.md)
- [Performance budgets](docs/performance-budgets.md)
- [Source register](docs/source-register.md)
- [Roadmap](docs/roadmap.md)
- [Branching and contribution workflow](docs/development-workflow.md)
- [Architecture decision records](docs/adr/README.md)

## Development principles

- Source code, identifiers, comments, and developer documentation are in English.
- Player-facing text is stored separately in translation resources; English and Russian are supported by the current HUD.
- Build in small, verifiable increments; never claim an unrun test passed.
- Develop on isolated codex/* branches. The repository owner controls main, develop, and all merges.
- Use original or appropriately licensed assets only.

## Validation

GitHub Actions runs Godot headless resource import, a main-scene smoke test, and the vertical-slice regression script. Manual visual and input testing is still required; the game is not yet a packaged release build.
