# Windows and Android release plan

Elemental Showdown remains **one Godot project**. Combat rules, campaign state, save schema, art and tests are shared. Windows and Android differ at the input, layout, device-integration and packaging edges. A Windows `.exe` and Android `.apk` must come from the same tested game revision.

## Current starting point

- `project.godot` uses Godot 4.5 and the Compatibility renderer, with `canvas_items` stretch and an expanding aspect. This is a reasonable mobile rendering starting point, but it does not prove phone usability.
- There is no `export_presets.cfg` yet. The Godot 4.5.1 editor is available. Android SDK environment variables are set, but the installed packages and matching export templates still need verification.
- `grid_overlay.gd` depends on mouse position and left/right mouse clicks; `player.gd` also uses hotkeys and right-click to change phase. Godot can emulate a left click from touch, but phone play needs explicit End Move, End Turn, Cancel and target-inspection actions.
- The hub, skill tree and calendar have dense desktop layouts and small controls. They need real phone-resolution and safe-area checks.
- Save files already use `user://`, which is the correct platform-relative location. Windows and Android each get their own local save storage; automatic cross-device sync is a separate feature.

## Code setup

1. Keep gameplay methods platform-neutral: `move_to_tile`, `select_skill`, `confirm_target`, `end_move`, `end_turn`, `cancel`, `open_menu`, `zoom_map`. Both platform interfaces call the same methods. Never make a second Android-only `Player` or `BattleManager`.
2. Define semantic actions in `project.godot`/Godot Input Map. Preserve current Windows keyboard and mouse mappings. Add Android buttons and gestures that dispatch those actions or invoke the same methods. An `InputEventScreenTouch` should use its own event position for grid taps rather than assuming a prior hover frame updated the tile.
3. Use a small platform presentation adapter for device facts: touch available, safe area, preferred UI scale and whether hover help is available. The HUD and hub select touch-friendly layouts from those facts. Platform checks do not change attack damage, AI, match rules or SP progression.
4. Keep landscape for the tactical arena on Android. Use responsive Godot containers, larger hit targets, readable text and a collapsible combat log. Give the arena enough space to inspect 18×10 tiles; use zoom/pan or a two-step tap confirmation if direct targeting becomes too small. Replace hover-only tooltips with tap-to-inspect panels.
5. Make deployment usable by tapping a fighter and then a destination tile; desktop drag-and-drop remains available. Add touch pan/zoom controls to the skill tree, calendar scrolling, and a visible Back/Close path for all popups. Test software keyboard entry during character creation.
6. Review `SettingsManager` so windowed/fullscreen controls appear only on Windows. Android gets only relevant settings such as audio, text/UI scale and optional vibration; saving the same settings file must work on both.

## Export setup

| Target | Preset and artifact | Additional setup |
| --- | --- | --- |
| Windows | `Windows Desktop` → `.exe` with its project data; create a zip for testers | Matching Godot export templates, icon, version, clean output directory. Optional code signing for public distribution. |
| Android testers | `Android` → signed debug `.apk` | Matching templates, Android SDK and Java paths, unique package ID, landscape orientation, launcher/adaptive icons, arm64 target and physical-device installation. |
| Android release | Signed release `.apk` for direct distribution or `.aab` for Google Play | Private release keystore stored outside the repository, version code/name, release signing and store-specific checks. |

Commit `export_presets.cfg` once created, but never commit signing keys, passwords or `.godot/export_credentials.cfg`. Put generated binaries under an ignored `builds/` or outside the repository. Use the same asset import settings and game revision for both targets. Do not use a hard-coded Windows file path inside a runtime scene or save path.

## Build order and verification

1. **Stabilize a build point.** Finish current gameplay edits, run the headless test suite, and record the revision. Windows is the quick baseline because its existing controls already work.
2. **Create both export presets.** Verify installed templates; export and launch Windows first. Verify Android SDK packages and produce a debug APK. An exported file is only the start of validation.
3. **Add touch input without changing combat rules.** Test mouse/keyboard and touch against the same input/action tests. No desktop hotkey or right-click can be the only way to perform a required action.
4. **Adapt layout and test devices.** Test at a small Android phone, a large phone/tablet and the current Windows resolution. Check landscape rotation, display cutouts, readable text, finger-sized controls, scene changes, pause/back behavior and returning after the app is suspended.
5. **Full gameplay smoke test on both.** Create a character, choose nationality/element, reach the hub, use the calendar, deploy, complete a 1v1 and 3v3, spend SP, rest/train, save, close and reload. Repeat after an app update so saves survive. Check combat frame rate and memory in 5v5 on a mid-range Android device before promising that mode to testers.
6. **Package the tested revision.** Run all automated tests, export both platforms, record checksums/version numbers and archive the two artifacts together. Inspect Android device logs for runtime errors and Windows logs for missing resources.

The first milestone is a **Windows tester build plus an installable Android debug APK**. The release milestone is that a new player can complete the same core career loop with touch on Android and mouse/keyboard on Windows, read every required screen, and reload progress on each platform. Store publication and cross-device cloud saves are later, separate milestones.
