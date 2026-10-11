# Performance Budgets

## Initial target
Desktop PC at 1920x1080, target 60 FPS. This is a goal to validate, not a guaranteed result. Final minimum specifications are established after profiling a representative vertical slice.

## Frame-time targets
- 60 FPS frame budget: approximately 16.67 ms.
- Track CPU frame time, GPU frame time, physics time, active NPC count, active vehicles, draw calls where tooling permits, memory, and loading times.
- Measure both a quiet area and the densest planned area.
- Use repeated captures and report median and high-percentile frame times, not only a single peak FPS number.

## Entity budgets
Initial budgets for active NPCs and vehicles are to be established experimentally. Start with conservative caps and instrument counts. Any increase must be supported by profiling on the reference machine.

## Optimization order
1. Fix correctness and avoid unnecessary work.
2. Profile a repeatable scenario.
3. Reduce expensive per-frame logic and redundant physics queries.
4. Apply simulation tiers and culling.
5. Optimize meshes, materials, shadows, and effects based on captures.
6. Re-run the same scenario and compare results.

## Acceptance
The selected reference machine should sustain the agreed target in the critical gameplay area without recurring frame-time spikes that make driving, aiming, or navigation unreliable. Any exception must include measurements and an explicit release decision.
