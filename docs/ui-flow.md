# Main Menu, Pause Menu, and Settings — M6

## Main menu

The project boots into a dedicated menu with **New Game**, **Continue**, **Settings**, and **Quit** actions. Continue is enabled only when a schema-valid primary save or backup exists. New Game resets the in-memory mission, economy, and wanted state before entering the gameplay scene. Continue validates and restores progression before entering gameplay.

## Pause menu

Press Escape during gameplay to pause the scene tree and open a pause overlay. The overlay supports Resume, Save, Load, Settings, Return to Main Menu, and Quit. The pause UI remains responsive while gameplay simulation is paused. Returning to gameplay restores the captured mouse cursor when running outside headless mode.

## Settings

The first settings increment contains English/Russian locale selection and mouse-camera sensitivity. Values are saved to `user://sunshine_state_settings.cfg`. Sensitivity changes apply immediately to the player and current vehicle cameras. The settings service clamps sensitivity to the documented supported range and ignores unsupported locale codes.

The language remains a presentation setting and does not alter mission, economy, or save-data identifiers.

## Automated coverage

The UI-flow regression validates menu/scene loading, conditional Continue enablement, settings panel open/close, locale updates, sensitivity updates, pause state, opening settings while paused, and returning to live gameplay.

## Remaining work

Controller navigation, remappable controls, resolution/fullscreen options, accessibility settings, audio controls, an explicit confirmation when starting over an existing save, polished visual transitions, sound/music, and packaged-build UX review remain outstanding. The presentation increment is not a release-ready UI.
