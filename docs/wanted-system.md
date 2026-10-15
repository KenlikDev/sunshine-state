# Wanted and Police System — M4

## Scope

This increment implements the authoritative wanted-state service and a small police perception/pursuit prototype. Combat, weapons, player health/death mechanics, mission-driven wanted clearing, and persistence are not part of this increment.

## Wanted state

The autoload `WantedSystem` owns wanted level (0–5), last-known player position, registered visible police detectors, and these states:

- `CLEAR`: wanted level is zero.
- `PURSUIT`: at least one police agent currently has line of sight to the player.
- `SEARCHING`: the police have lost sight of the player or a witnessed crime has just been reported.
- `COOLING_DOWN`: the search timer expired; wanted level will decay one level per configured interval unless police reacquire the player.

Crimes use the shared `report_crime` API with type, severity, player position, witness context, and source ID. Invalid crime types or non-positive severities are rejected. Wanted-level changes and state transitions are exposed through signals and optional development logging.

## Police agent

The current police prototype follows an authored patrol loop when no wanted level is active. During pursuit it performs a range-limited line-of-sight ray query and moves toward the player. After occlusion it moves toward the last-known position in the search state. The wanted service remains authoritative; the police agent reports detections but never changes the wanted level directly.

## Example interaction

The district contains a clearly marked greybox property-damage interaction. Using it reports a witnessed crime and increases wanted level. The HUD displays the active wanted level and localised state. The crime interaction has a short cooldown to avoid accidental repeated level increases from a held/repeated interaction.

## Automated coverage

The wanted regression scene checks:
- crime severity, last-known position, and rejection of invalid events
- central police detector registration and pursuit/search transitions
- search expiry, level-by-level decay, and clearing at level zero
- player crime interaction and cooldown
- police line-of-sight pursuit, occlusion-driven search, and reacquisition
- explicit wanted clearing with the `PLAYER_DEATH` reason

## Remaining acceptance work

The complete MVP still requires scripted vehicle-change scenarios, a real player health/death/respawn system, save/load policy integration, more comprehensive search-area behaviour and long-run tests. Weapons/combat are a separate required gameplay increment and are not implemented here. Police movement uses direct pursuit toward the player/last-known position; a baked navigation solution and traffic-aware police vehicle pursuit remain outside this prototype.
