# Vehicle System — M2

## Goal

M2 introduces the first drivable vehicle and establishes a clear boundary between on-foot movement and vehicle control. This is a physics-driven prototype with original primitive geometry, not final handling or production vehicle art.

## Runtime contract

- Vehicles expose `get_interaction_prompt_key()` and `interact(actor)` for the shared interaction system.
- The player transfers control through `enter_vehicle(vehicle)`; a vehicle accepts only one driver.
- The on-foot controller stops processing movement while the player is in a vehicle.
- The vehicle controller owns throttle, reverse, braking, steering, and camera look while occupied.
- Exiting searches nearby candidate positions and uses a capsule overlap query to avoid placing the player inside blocking geometry.
- Pressing R while driving searches for a nearby clear recovery position, uses ground raycasts and a chassis overlap check, levels the vehicle, and clears linear/angular velocity. Recovery is refused when no safe candidate is available.
- Significant horizontal contacts emit throttled HUD feedback; ordinary ground contact does not trigger collision messages.
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
| R | Reserved | Recover a blocked or overturned vehicle |
| R | Reserved | Recover a blocked or overturned vehicle |
| Escape | Release mouse cursor | Release mouse cursor |
| F6 | Toggle English/Russian | Toggle English/Russian |

## Validation

GitHub Actions imports the project and runs a dedicated vehicle regression scene. The automated checks cover all three vehicle configurations and distinct power tuning, vehicle discovery, entry, driver ownership, player visibility and collision handoff, forward motion under throttle, braking deceleration, steering path change, static barrier collision, impact feedback, blocked-footprint recovery, upright orientation restoration, velocity reset, exit state restoration, and entry/exit feedback.

These checks do not prove driving feel. Manual testing must still check steering response, braking distance, collision behaviour, suspension stability, camera placement, recovery on uneven terrain, and handling differences between the sedan, compact coupe, and pickup. The R recovery control is a gameplay assist and is not a substitute for validating suspension and collision response.

## Known limitations

- Three original greybox configurations are present: sedan, compact coupe, and utility pickup. Each has separate mass, engine/brake/steering tuning, wheelbase, wheel radius, recovery footprint, camera placement, and silhouette. These are prototypes rather than final vehicle art.
- Handling values are starting points and need tuning on the target machine.
- Traffic AI, road rules, damage, vehicle persistence, garages, and player vehicle ownership are not implemented yet.
