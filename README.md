# Sunshine State

Sunshine State is an original, single-player, third-person open-world crime-action game built with Godot 4, with Blender used for 3D asset creation.

The project aims to develop a playable, systems-driven open world through deliberate milestones, documented technical decisions, and repeatable validation. It is an independent project and will not use proprietary GTA assets, code, branding, or other protected material.

## Project Status

**Stage:** Foundation and MVP definition.

The current priority is to establish the project vision, define a realistic MVP scope, document the technical architecture and production pipeline, and prepare a minimal Godot project structure. This repository is not yet a playable MVP.

## Development Principles

- Plan and review scope before implementation.
- Build in small, verifiable increments.
- Keep source code, developer documentation, and code comments in English.
- Treat Russian as a planned in-game localization, not as the language of source files or developer documentation.
- Do not claim a build or test passed unless it was actually run and its result recorded.
- Develop on focused feature branches and submit changes for review; the repository owner controls merges.
- Prefer original assets and clearly documented third-party resources with appropriate licenses.

## Planned Technology

- **Engine:** Godot 4
- **3D asset creation:** Blender
- **Version control and automation:** Git and GitHub Actions

Exact engine versions, platform targets, and dependencies must be pinned and validated as implementation begins.

## Documentation

- [Game vision](docs/vision.md)
- [MVP scope and acceptance criteria](docs/mvp-scope.md)
- [Architecture](docs/architecture.md)
- [Gameplay systems](docs/gameplay-systems.md)
- [Art and asset pipeline](docs/art-pipeline.md)
- [Testing strategy](docs/testing-strategy.md)
- [Performance budgets](docs/performance-budgets.md)
- [Source register](docs/source-register.md)
- [Roadmap](docs/roadmap.md)
- [Branching and contribution workflow](docs/development-workflow.md)
- [Architecture decision records](docs/adr/README.md)
- [Foundation status and validation gaps](docs/foundation-status.md)

## Proposed Branch Model

- `main`: reviewed release-quality history only
- `develop`: integration branch managed by the repository owner
- `codex/*`: isolated work branches for individual tasks

Do not merge a milestone until its acceptance criteria and required checks pass. The repository owner retains final merge authority.

## Current Limitations

This package is documentation and repository scaffolding only. It does not contain a playable game, finished 3D assets, or a verified Godot export. Those claims must not be made until implementation and validation are complete.
