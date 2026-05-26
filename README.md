# Data Entry Autonoma

**By [Jayrr Dev](https://github.com/Jayrr-Dev)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Record mouse clicks, scrolls, and keyboard triggers once — then run automated data entry with saved presets or CSV batch files. Built with AutoHotkey v2 for Windows.

## Features

- **Record** — Capture click targets, scroll actions, and variable keys in one session
- **Run** — Replay recordings with human-like mouse movement and typing
- **Shift-hold delays** — Hold Shift while recording to insert timed pauses
- **CSV batch** — Run the same recording once per CSV row with different variable values
- **Presets** — Save run speed, typing speed, and variable text lists
- **Recordings table** — View recording name and variable count at a glance
- **CRUD** — Rename, edit, and delete recordings and presets from the UI
- **Standalone exe** — Compile to `DataEntryAutonoma.exe`; end users do not need AutoHotkey installed
- **Single instance** — Only one app window runs at a time

## Requirements

| Use case | Requirement |
|----------|-------------|
| Development | [AutoHotkey v2](https://www.autohotkey.com/) |
| End users | `DataEntryAutonoma.exe` only (see [BUILD.md](BUILD.md)) |

## Quick start

1. Clone this repository
2. Run `dataEntryAutonoma.ahk`
3. Click **Record** to capture clicks, scrolls, and keys (Esc saves; Cancel on the dialog discards)
4. Create a preset under **Edit Preset** or prepare a CSV batch file
5. Select a recording and preset (or CSV), then click **Run**

## Project layout

```
DataEntryAutonoma/
  dataEntryAutonoma.ahk   # Main application
  LICENSE                 # MIT license (attribution required)
  compile.ps1             # Build standalone exe
  build.bat               # Build shortcut
  BUILD.md                # Detailed build & distribution guide
  recordings/             # Session logs (di-*.log)
  saved-inputs/           # Variable presets (*.txt)
  apply-state.ini         # Last selected recording / preset / CSV (auto-created)
  dist/                   # Compiled exe output (after build)
```

## CSV batch format

Each row runs one full pass through the selected recording:

```csv
1,word,word2,word3
2,word4,word5,word6
```

- Column 1 is a row label (shown in status)
- Remaining columns map to `variable-1`, `variable-2`, etc.
- Lines starting with `#` and blank lines are ignored

## Build executable

From the project root:

```powershell
.\compile.ps1
```

Output: `dist\DataEntryAutonoma.exe`

See [BUILD.md](BUILD.md) for distribution layout and prerequisites.

## Workflow tips

- After each click during recording, press any key to mark a variable step (optional for click-only targets)
- Hold **Shift** during recording to add a timed delay; release to confirm
- A persistent tooltip shows **Esc = Save** while recording
- During Run, tooltips show **Assigned Var 1**, **Assigned Var 2**, etc.
- Esc stops recording, a run, or an entire CSV batch

## License & attribution

This project is **open source** under the [MIT License](LICENSE).

You may use, modify, and distribute this software freely, but **you must give credit to Jayrr Dev**:

1. Keep the [LICENSE](LICENSE) file and copyright notice in all copies or substantial portions of the software.
2. Include attribution in documentation, about screens, or README when you redistribute or build on this project — for example:

   > Based on [Data Entry Autonoma](https://github.com/Jayrr-Dev/DataEntryAutonoma) by [Jayrr Dev](https://github.com/Jayrr-Dev).

The MIT license legally requires the copyright and permission notice to remain intact; the attribution above is the expected way to credit the original author.

## Author

**Jayrr Dev** — [github.com/Jayrr-Dev](https://github.com/Jayrr-Dev)
