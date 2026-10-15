# Asset and License Inventory

**Status:** Initial inventory for the greybox prototype; not final release approval.
**Last repository scan:** 2026-10-15
**Baseline scan revision:** `9a7ce08880da30cc90d41538eaa21610d2884c3b` (includes the procedural audio service and current UI/settings prototypes)

## Current project-authored content

| Item | Files / locations | Origin | License / attribution status | Ship status |
|---|---|---|---|---|
| Greybox coastal district geometry, roads, sidewalks, boundaries, water and buildings | `scripts/world/greybox_district.gd`, `scenes/world/greybox_district.tscn` | Procedurally created from project-authored Godot scripts and primitive meshes | Original project placeholder content; no external asset licence identified | Prototype only; art replacement requires a new inventory entry |
| Player, sedan, compact coupe, pickup, traffic, pedestrian, and police placeholder shapes | `scenes/player/`, `scenes/vehicles/`, `scenes/traffic/`, `scenes/pedestrians/`, `scenes/police/` and related scripts | Godot primitive meshes, materials, and project-authored scene composition | Original project placeholder content; no imported third-party models identified | Prototype only; art replacement requires a new inventory entry |
| Main/pause/settings/HUD interface | `scripts/ui/`, `scenes/ui/`, `localization/ui_table.txt` | Project-authored UI code and English/Russian text; standard Godot controls/theme | No custom image/font asset identified. The engine runtime and bundled engine components remain subject to their upstream notices | Prototype only; user-facing art and accessibility review remain |
| Mission and economy catalogues | `data/missions/missions.json`, `data/items/items.json` | Project-authored game data | Original project data; no external content identified | Prototype data |
| Procedural ambient music and gameplay/UI sound effects | `scripts/systems/audio_service.gd`, `tests/test_audio_system.gd` | PCM samples synthesized at runtime from project-authored waveforms and simple signal/noise formulas; no imported audio files | Project-authored procedural implementation; no third-party samples identified. Sound design remains prototype quality and needs listening review | Development baseline; not a final soundscape |
| Godot Engine runtime and standard engine UI resources | Godot 4.7.2-stable export runtime | Upstream Godot Engine | MIT license; notice text is included in `LICENSES/GODOT_ENGINE_LICENSE.txt`. Godot also ships third-party components under their own notices; see the official [Godot license page](https://godotengine.org/license/) and ensure the matching pinned-distribution copyright notice is retained for a release | Required runtime dependency |

## Imported asset scan

At the scanned revision, the repository tree contained **no committed files** with common imported media/model formats such as PNG/JPEG/WebP/SVG, WAV/OGG/MP3, TTF/OTF/WOFF, BLEND, GLB/GLTF, OBJ/FBX/DAE, or Godot imported resource formats. Current game geometry is generated through scenes and scripts rather than imported art files.

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
