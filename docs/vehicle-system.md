# Vehicle System — M2

## Goal

M2 introduces the first drivable vehicle and establishes a clear boundary between on-foot movement and vehicle control. This is a physics-driven prototype with original primitive geometry, not final handling or production vehicle art.

## Runtime contract

- Vehicles expose `get_interaction_prompt_key()` and `interact(actor)` for the shared interaction system.
- The player transfers control through `enter_vehicle(vehicle)`; a vehicle accepts only one driver.
- The on-foot controller stops processing movement while the player is in a vehicle.
- The vehicle controller owns throttle, reverse, braking, steering, and camera look while occupied.
- Exiting searches nearby candidate positions and uses a capsule overlap query to avoid placing the player inside blocking geometry.
- The vehicle is a `VehicleBody3D` with four `VehicleWheel3D` nodes and a separate interaction area.

## Controls

| Input | On foot | In a vehicle |
|---|---|---|
| W / S | Move forward / backward | Accelerate / reverse |
| A / D | Strafe | Steer |
| Left Shift | Sprint | Reserved |
| Space | Jump | Brake |
| Mouse | Orbit player camera | Orbit vehicle camera |
| E | Interact / enter vehicle | Exit vehicle |
| Escape | Release mouse cursor | Release mouse cursor |
| F6 | Toggle English/Russian | Toggle English/Russian |

## Validation

GitHub Actions imports the project and runs a dedicated vehicle regression scene. The automated checks cover vehicle discovery, entry, driver ownership, player visibility and collision handoff, forward motion under throttle, exit state restoration, and entry/exit feedback.

These checks do not prove driving feel. Manual testing must still check steering response, braking distance, collision behaviour, suspension stability, camera placement, and recovery on uneven terrain.

## Known limitations

- The current implementation contains one vehicle configuration, while the final MVP requires at least three distinct configurations.
- Handling values are starting points and need tuning on the target machine.
- Traffic AI, road rules, damage, vehicle persistence, garages, and player vehicle ownership are not implemented yet.
