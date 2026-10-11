# Foundation Status

## Included in this foundation proposal
- Product vision and required MVP scope
- Architecture and gameplay-system contracts
- Blender-to-Godot asset pipeline policy
- Test strategy, performance targets, source register, and roadmap
- Branch workflow and a minimal repository CI check
- Minimal Godot project entry scene for editor/import smoke testing

## Not included
- Player controller, vehicles, NPC AI, combat, police, missions, or save/load implementation
- Finished art, audio, animation, or world assets
- A verified exported game build

## Validation still required
1. Review the proposed foundation and MVP acceptance criteria.
2. Install a selected stable Godot 4 version and validate the project in editor and headless mode.
3. Record the exact Godot version and target test machine.
4. Review the proposed rendering backend on the target hardware.
5. Expand CI to include engine-based validation once the version and runner approach are selected.

This repository is public by owner decision. The first bootstrap commit to `main` was explicitly authorized by the repository owner. Further foundation changes are isolated on `codex/foundation` for review. No Godot runtime validation is claimed yet.
