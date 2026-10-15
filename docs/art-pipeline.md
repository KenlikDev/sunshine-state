# Art and Asset Pipeline

## Source and export formats
- Blender source: `.blend`
- Preferred interchange: glTF 2.0 (`.glb` for self-contained assets where appropriate)
- Textures: use engine-supported formats and document source/export settings
- Audio: use Godot-supported formats with source files retained where licensing permits

## Blender conventions
- Apply transforms intentionally; use a consistent real-world scale.
- Define forward/up axis conventions and validate them with a test asset.
- Use descriptive object/material names; remove unused datablocks before export.
- Keep collision geometry simple and separate where useful.
- Use LODs for assets that justify them; do not add LOD complexity without a measured benefit.
- Maintain clean UVs and material counts appropriate to the target hardware.
- Keep source files in `assets/source_blender/` and runtime exports in the relevant `assets/` subdirectory.

## Import checklist
1. Confirm scale, origin, orientation, and pivot.
2. Confirm materials and texture paths.
3. Confirm collision shape and collision layers.
4. Confirm animation skeleton and naming where applicable.
5. Confirm the asset works in a minimal test scene.
6. Record source, creator, license, attribution, and modification status.
7. Confirm the exported asset contains no unlicensed third-party content.

## Asset licensing
Maintain an inventory for every external asset. Do not commit ripped game assets, leaked proprietary assets, unlicensed music, or copied brand/trademark designs. Keep provenance evidence with the asset record.

## Current inventory

The current committed resource baseline is tracked in [the asset and license inventory](asset-license-inventory.md). Before adding any third-party model, texture, image, font, sound, music, plugin, or code dependency, record its source URL, creator, license and required attribution, modification status, and included file paths. An asset must not enter the build until the license terms have been reviewed for the intended use and redistribution.
