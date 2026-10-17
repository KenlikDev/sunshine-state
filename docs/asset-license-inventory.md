# Asset and License Inventory

**Status:** Current inventory for the visual-foundation prototype; not final release approval.
**Last repository scan:** 2026-10-17
**Baseline scan revision:** `9a7ce08880da30cc90d41538eaa21610d2884c3b` (includes the procedural audio service and current UI/settings prototypes)

## Current project-authored content

| Item | Files / locations | Origin | License / attribution status | Ship status |
|---|---|---|---|---|
| Greybox coastal district geometry, roads, sidewalks, boundaries, water and buildings | `scripts/world/greybox_district.gd`, `scenes/world/greybox_district.tscn` | Procedurally created from project-authored Godot scripts and primitive meshes | Original project placeholder content; no external asset licence identified | Prototype only; art replacement requires a new inventory entry |
| Player, pedestrian, and police humanoid model | `assets/characters/quaternius_animated_man.glb`, `assets/characters/QUATERNIUS_ANIMATED_MEN_LICENSE.txt`, `scripts/gameplay/stylized_character_mesh.gd` | Rigged Quaternius Animated Men character (bundled via the public `kendrekaran/striker-3d` example repository) | CC0 1.0 Universal per the retained upstream Quaternius license notice; mesh and animations are imported without upstream project code. Source/provenance: [upstream asset copy](https://github.com/kendrekaran/striker-3d/blob/main/assets/player.glb), [license notice](https://github.com/kendrekaran/striker-3d/blob/main/assets/LICENSE-quaternius.txt), [Quaternius](https://quaternius.com/) | Allowed for prototype redistribution under CC0; retain the bundled notice and verify upstream contents before commercial release |
| Drivable and background traffic vehicle meshes | `assets/vehicles/kenney_sedan.glb`, `assets/vehicles/kenney_hatchback_sports.glb`, `assets/vehicles/kenney_utility_truck.glb`, `assets/vehicles/KENNEY_CAR_KIT_LICENSE.txt`, `scripts/gameplay/vehicle_glb_visual.gd` | Kenney Car Kit GLB conversions distributed in the Tiny Game Engine asset catalog | CC0 1.0 Universal; the intermediary repository states all models were created by Kenney and converted with textures embedded. Source/provenance: [Kenney Car Kit](https://kenney.nl/assets/car-kit), [model files](https://github.com/Hidencod/tge-assets/tree/main/packs/car-kit), [retained license](https://github.com/Hidencod/tge-assets/blob/main/LICENSE) | Allowed for prototype redistribution under CC0; retain the bundled notice and verify model dimensions/materials and final release notices |
| Eight core-district building models (five reusable variants) | `assets/environment/kenney_building_*.glb`, `assets/environment/KENNEY_CITY_KIT_LICENSE.txt`, `scripts/world/building_glb_visual.gd` | Kenney City Kit Commercial GLB conversions from the Tiny Game Engine model catalog | CC0 1.0 Universal; the upstream catalog states all models were created by Kenney and the converted GLBs embed their textures. Source/provenance: [Kenney City Kit Commercial](https://kenney.nl/assets/city-kit-commercial), [model files](https://github.com/Hidencod/tge-assets/tree/main/packs/city-kit-commercial), [retained license](https://github.com/Hidencod/tge-assets/blob/main/LICENSE) | Allowed for prototype redistribution under CC0; keep collision hulls separate and visually review the imported models before release |\n| Procedural human fallback, roads, sidewalks, coastal props, and four secondary building facades | `scripts/gameplay/stylized_character_mesh.gd`, `scripts/gameplay/vehicle_visual_details.gd`, `scripts/world/stylized_city_art.gd`, `scenes/traffic/` and `scripts/world/greybox_district.gd` | Project-authored meshes/materials and scene composition | Original project-authored presentation work; roads, coastal props and four secondary building facades remain procedural blockout geometry | Prototype only; final-art milestone remains open |
| Main/pause/settings/HUD interface | `scripts/ui/`, `scenes/ui/`, `localization/ui_table.txt` | Project-authored UI code and English/Russian text; standard Godot controls/theme | No custom image/font asset identified. The engine runtime and bundled engine components remain subject to their upstream notices | Prototype only; user-facing art and accessibility review remain |
| Mission and economy catalogues | `data/missions/missions.json`, `data/items/items.json` | Project-authored game data | Original project data; no external content identified | Prototype data |
| Procedural ambient music and gameplay/UI sound effects | `scripts/systems/audio_service.gd`, `tests/test_audio_system.gd` | PCM samples synthesized at runtime from project-authored waveforms and simple signal/noise formulas; no imported audio files | Project-authored procedural implementation; no third-party samples identified. Sound design remains prototype quality and needs listening review | Development baseline; not a final soundscape |
| Godot Engine runtime and standard engine UI resources | Godot 4.7.2-stable export runtime | Upstream Godot Engine | MIT license; notice text is included in `LICENSES/GODOT_ENGINE_LICENSE.txt`. Godot also ships third-party components under their own notices; see the official [Godot license page](https://godotengine.org/license/) and ensure the matching pinned-distribution copyright notice is retained for a release | Required runtime dependency |

## Imported asset scan

The current visual-foundation branch includes one rigged humanoid GLB, three Kenney Car Kit vehicle GLBs reused for driving and traffic, and five reusable Kenney City Kit Commercial building GLBs, with CC0 1.0 notices retained under `assets/`. Four buildings remain procedural facade blockouts; roads, beach props, palms and street furniture remain generated with project-authored meshes and scripts.

This is a point-in-time repository scan, not a guarantee about untracked local files or assets added later. CI checks require this inventory and the engine license notice but do not automatically establish the licence of a newly added resource; every new asset must be reviewed and recorded.

## Required record for future content

Add one row per asset or coherent asset pack before it is merged:

- Stable inventory ID and in-repository paths
- Asset name, creator, and source URL
- Exact license name/version and a retained copy or link to the license terms
- Required attribution, notices, restrictions, and proof of commercial/redistribution rights
- Whether the asset has been modified and how
- Import/export formats and any upstream source files
- Reviewer and review date
- Target platforms and intended shipped uses

## Release restrictions

- Do not include ripped, leaked, stolen, or otherwise unauthorized proprietary content.
- Do not infer a licence from an asset being free to download or publicly visible.
- Do not merge external assets when the provenance, license, or required attribution is unknown.
- Before shipping, verify engine and bundled third-party notices against the exact pinned Godot distribution, and include all required notices in the packaged documentation/credits.
- An original procedural ambient/SFX baseline now exists in code; musical composition, sound quality, mixing, additional contextual cues, production art, accessibility review, and the final third-party notice audit remain release gates. The lack of imported audio samples does not mean audio acceptance is complete.
