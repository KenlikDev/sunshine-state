# Missions, Economy, and Persistence — M5

## Mission chain

Three data-driven missions are defined in `data/missions/missions.json`. Each definition names a target node in the district, allowing the HUD to show a directional arrow and distance. Guidance measures position and heading from the player while on foot and from the driven vehicle while seated. Advancing or completing a mission automatically redirects or clears the active waypoint.

1. **District orientation** — interact with the district information board; reward: 100.
2. **Property report** — use the property-damage interaction; reward: 200.
3. **Supply run** — purchase a first-aid kit from the vendor; reward: 300.

The mission director owns the current mission and explicit `LOCKED`, `ACTIVE`, `FAILED`, and `COMPLETED` states. Prerequisites prevent objectives from counting out of sequence. Player death fails the active mission. Press F8 to restart an active or failed mission. Mission reward transactions use stable idempotency keys so a repeat event cannot award the same mission twice.

## Economy

Items and prices live in `data/items/items.json`. All transactions go through `EconomyService`, which checks catalog membership, affordability, balance bounds, inventory, and transaction IDs. The current catalogue contains a first-aid kit (100) and a vehicle repair service (150). Press H to consume one first-aid kit and restore up to 50 health. Vehicle collisions reduce vehicle health and proportionally reduce engine power; use the vehicle-service desk while a damaged car is within its service radius to pay 150 and restore the car to full health. Repair services debit currency without creating a duplicate inventory token.

## Save schema

`SaveService` stores schema version 1 in `user://sunshine_state_save.json`. The payload contains currency/inventory/processed transactions, mission states/current mission, wanted level/last known position, a timestamp, selected world progression flags, and the day-night clock when the environment is active. The `time_of_day_hours` world field is optional for backward compatibility with existing schema-version-1 saves; when present it must be numeric and in the range 0–24 (exclusive at 24).

Writes go to a temporary file first. Before replacing a valid primary save, the previous valid version is rotated into `user://sunshine_state_save.bak`. Load validates the complete payload before applying data. If the primary is invalid, a validated backup is tried; if neither is valid, the service reports failure and leaves the in-memory state untouched. Unsupported schema versions are rejected rather than silently rewritten.

F5 saves on demand; F9 loads. Important mission, transaction, and wanted-level changes are autosaved after the current event stack completes. F8 restarts an active/failed mission.

## Automated coverage

The progression test covers item catalogue loading, successful and repeated purchases, duplicate transaction rejection, insufficient funds, negative-balance prevention, mission prerequisite sequencing, fail/restart, unique mission rewards, a complete three-mission path, first-aid consumption/healing, vehicle damage/repair/payment, day-night time validation and round-trip/backup restoration, save serialization, autosaved transaction state, and recovery from a corrupt primary save using the last known-good backup. A separate vehicle regression verifies that a physics collision reduces vehicle health.

## Remaining acceptance work

This is an early progression foundation. Manual menu flows, mission failure variety, mission replay UI, a save-slot UI, schema migration beyond version 1, and full persistence policy for individual vehicle/NPC transforms remain outstanding. Vehicle damage currently persists only for the current session and is reset when the world is reconstructed. The project still requires manual play testing and the M3 15-minute simulation soak.
