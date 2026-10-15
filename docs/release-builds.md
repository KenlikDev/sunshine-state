# Desktop Export and Release Smoke Tests

## Supported development presets

The committed `export_presets.cfg` defines two 64-bit desktop presets: **Windows Desktop** and **Linux/X11**. The non-resource export filter includes `*.txt` and `*.json`, which are loaded directly at runtime. The bilingual key table is stored as CSV-formatted plain text in `localization/ui_table.txt` so Godot's CSV translation importer does not convert it into a resource that `FileAccess` cannot open from the exported pack. The presets contain no signing certificates, encryption keys, or per-machine credentials. Local export credentials, if ever added, belong in Godot's ignored credentials file and must not be committed.

The normal CI export job uses Godot 4.7.2 and installs the matching export templates. It creates both packages under `build/`, validates that the files are non-empty, and starts the exported Linux executable in headless mode without the editor. The job uploads both artifacts as `sunshine-state-desktop-builds` for seven days.

## Local build commands

Install the pinned Godot 4.7.2 release and its export templates, then run these commands from the repository root:

```sh
mkdir -p build
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Windows Desktop" build/SunshineState.exe
godot --headless --path . --export-release "Linux/X11" build/SunshineState.x86_64
```

On Linux, the executable can be smoke-tested with:

```sh
timeout 30s build/SunshineState.x86_64 --headless --quit-after 2
```

Godot's official [project export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html) explains export templates, committed presets, and command-line export flags.

## What CI proves—and what it does not

CI verifies that the two desktop packages can be exported, that the Linux binary starts headlessly, and that the resource/script regression suite still passes. It does not prove Windows runtime compatibility, visual/audio quality, signing, installer behaviour, graphics-driver compatibility, controller support, or performance on a player's machine.

## Remaining release gates

- Run the Windows package on a clean Windows machine without the Godot editor installed.
- Play through the documented critical path using exported builds and confirm saves/settings persist after closing and relaunching.
- Record tested OS build, CPU/GPU, drivers, renderer, and display resolution.
- Complete the asset-license inventory before shipping any final art/audio.
- Prepare a known-issues list, release notes, and install/run instructions.
- Add code signing or installer packaging only when ownership certificates and target distribution requirements are clear; do not commit credentials.
