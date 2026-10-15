# Main Menu, Pause Menu, and Settings — M6

## Main menu

The project boots into a dedicated menu with **New Game**, **Continue**, **Settings**, and **Quit** actions. Continue is enabled only when a schema-valid primary save or backup exists. New Game resets the in-memory mission, economy, and wanted state before entering the gameplay scene. Continue validates and restores progression before entering gameplay.

## Pause menu

Press Escape during gameplay to pause the scene tree and open a pause overlay. The overlay supports Resume, Save, Load, Settings, Return to Main Menu, and Quit. The pause UI remains responsive while gameplay simulation is paused. Returning to gameplay restores the captured mouse cursor when running outside headless mode.

## Settings

Starting a new game shows a localized confirmation if a valid save exists; canceling the dialog does not reset the live mission, money, inventory, or wanted state. Existing save files are retained, so Continue remains available after choosing to restart.

Settings provide English/Russian locale selection, mouse-camera sensitivity, window resolution presets, fullscreen mode, master volume, and a dedicated keyboard-bindings panel. Supported actions can be rebound to physical keys, conflicts are rejected, Escape cancels an in-progress capture, and bindings persist with the other user settings. Mouse fire/aim remain available while optional keyboard bindings can be added. Values are saved to `user://sunshine_state_settings.cfg`. Sensitivity changes apply immediately to the player and vehicle cameras; volume changes update the Master audio bus immediately. The settings service clamps numeric values to supported ranges and ignores unsupported locale codes. Display-mode changes are skipped in headless mode.

The bilingual English/Russian key table is maintained as CSV-formatted text in `localization/ui_table.txt`. It is parsed by the localization service at runtime and included in desktop exports as a non-resource data file. The language remains a presentation setting and does not alter mission, economy, or save-data identifiers.

## Automated coverage

The UI-flow regression validates menu loading, Continue disabled without a save and enabled with one, new-game confirmation/cancel without losing in-memory progression, settings panel open/close, locale and sensitivity persistence, resolution/fullscreen/master-volume/keyboard-binding persistence, conflict rejection, default reset, pause state, opening settings while paused, and returning to live gameplay.

## Remaining work

Controller navigation, accessibility settings, separate music/effects controls, polished visual transitions, sound/music, and packaged-build UX review remain outstanding. The presentation increment is not a release-ready UI.
