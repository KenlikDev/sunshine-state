# Combat and Damage System — M4

## Current weapon

This increment introduces one original sidearm prototype rather than a broad weapon catalogue. It supports center-screen camera ray aiming, magazine ammunition, reserve ammunition, a fire interval, manual reload, maximum hit range, and a field-of-view change while aiming.

- Left mouse button: fire
- Right mouse button: aim
- T: reload

The weapon performs a physics ray query through collision layer 1, excludes the player body, and applies damage only to targets exposing a `Damageable` component. A blocked ray does not penetrate walls or unrelated collision bodies. Out-of-range objects do not take damage.

## Health and death

The reusable `Damageable` component owns health, rejects zero/negative damage and repeat damage after death, emits health changes, and calls a target's death handler or queues the target for removal. It is attached to the player, pedestrian agents, and police officer.

Player lethal damage triggers an incapacitated window, clears wanted state with the `PLAYER_DEATH` reason, and respawns the player at the original spawn transform with full health. A police officer can perform a simple line-of-sight attack inside a short range while pursuit is active. Its damage output is deterministic so automated gameplay tests remain stable.

## Automated checks

The combat regression scene checks:
- camera ray hit detection and deterministic damage
- fire-rate cooldown and ammunition consumption
- target removal after lethal damage
- range rejection for targets beyond weapon range
- reload transfer and rejection when no reserve ammunition remains
- aim FOV switching and restoration
- police damage while a wanted state is active and line of sight is clear
- player death, wanted clear, and automatic respawn with full health

## Remaining work

This is a single-weapon prototype, not a balanced combat system. Weapon animations, audio, recoil, impact effects, hit reactions, enemy combat tactics, weapon switching, controller aim support, damage indicators, difficulty tuning, and manual gameplay review remain required. Player and police animation are currently represented by primitive geometry and state logic.
