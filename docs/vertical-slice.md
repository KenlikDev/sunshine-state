# M1 Vertical Slice

## Purpose

M1 establishes the first interactive, playable foundation of Sunshine State before vehicles, police, combat, and mission progression are introduced. The district is a greybox made from original primitive geometry; it is test content rather than final art.

## Included in this increment

- Third-person CharacterBody3D with walking, sprinting, jumping, collision, and camera orbit.
- A bounded, connected coastal district with roads, sidewalks, blockout buildings, a beach, and basic directional lighting.
- A shared interactable contract demonstrated by an information board.
- An in-game HUD with controls, interaction prompts, status feedback, and English/Russian localization loaded from a CSV table by a dedicated runtime service.
- A headless regression scene that checks bootstrap composition, interaction availability, and Russian localization.

## Controls

| Input | Action |
|---|---|
| W / A / S / D | Move |
| Left Shift | Sprint |
| Space | Jump |
| Mouse | Orbit camera |
| E | Interact with the information board |
| Escape | Release the mouse cursor |
| Left-click | Capture the mouse cursor again |
| F6 | Toggle English/Russian |

## Validation status

The automated checks are run in GitHub Actions by launching the project with the regression scene as the main scene. A headless scene load is not a substitute for manual playtesting. Manual verification is still required for feel, camera clipping, collision edges, UI scaling, and the district's visual readability on the target machine.

## Not included yet

Vehicles, pedestrian or traffic AI, police/wanted logic, combat, missions, economy, persistence, final assets, audio, settings menus, and packaged release builds remain outside this increment. These are required MVP work, not completed features.
