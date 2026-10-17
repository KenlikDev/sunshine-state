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


## Current presentation pass

The coastal district uses an original, stylized coastal-city presentation target: sun-warmed plaster, cream trim, aqua and coral accents, a time-varying procedural sky, warm street lighting after dusk, palms, a beach promenade, and readable pedestrian crossings. Eight core buildings now use imported Kenney City Kit Commercial low-poly GLBs with embedded textures. The original static collision boxes remain independent of the render models; four secondary buildings retain procedural facades with instanced windows and trim.

The player, pedestrian, and police capsule placeholders now use a bundled rigged and animated Quaternius humanoid GLB under CC0 1.0. The game scales the imported rig to the existing gameplay height, applies separate clothing colours, blends idle/walk/run transitions with speed smoothing and hysteresis, and selects a run clip for fleeing pedestrians and pursuing officers. A small velocity-driven lean adds movement response without modifying the imported rig animation tracks. The police character receives role-specific cap and badge details. A procedural articulated human remains as a fallback if a valid imported rig cannot be loaded. The imported character is a meaningful step beyond capsules but is still a reusable low-poly base—not a bespoke, production-quality protagonist. Facial expression, bespoke character design, combat/weapon animations, and animation polishing remain open.

The three drivable vehicle variants now use Kenney Car Kit low-poly glTF meshes (sedan, sports hatchback and utility truck) under CC0 1.0. Existing VehicleBody3D physics, collision shapes, steering, and interaction logic remain unchanged; the old cuboid render meshes are hidden and the GLBs are uniformly fitted to target bounds. The traffic agents still use procedural blockout cars. These vehicle models are coherent reusable low-poly assets, but model-specific deformation, detailed damage, and a manual in-motion inspection remain open.

The coastline now uses a tessellated, vertex-animated water shader with ripples and restrained glints; its palette and warm building-window emission follow the day/night cycle. Ninety-six palm fronds sway with phase offsets so the promenade does not move as a single rigid group. Streetlight intensity fades gradually through twilight, and a restrained contrast/saturation grade strengthens color separation. Background traffic now has emissive head/tail lamp geometry: headlights follow the shared day/night cycle, and tail lamps brighten in waiting/yielding/recovery states without adding per-car dynamic lights. These effects use in-project shader/script code and add no physics bodies. Any later third-party models or textures must be recorded in the asset/license inventory before entering the build. Visual acceptance still requires an exported in-engine review on the target display and should not be inferred from a successful headless test.
