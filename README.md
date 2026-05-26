# Data Entry Autonoma

**By [Jayrr Dev](https://github.com/Jayrr-Dev)**

Record mouse clicks, scrolls, and keyboard triggers once — then replay automated data entry with saved presets or CSV batch files. Built with AutoHotkey v2 for Windows.

## Features

- **Detect** — Record click targets, scroll actions, and variable keys in one session
- **Apply** — Replay recordings with human-like mouse movement and typing
- **CSV batch** — Run the same recording once per CSV row with different variable values
- **Presets** — Save playback speed, typing speed, and variable text lists
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
3. Click **Detect** to record — click targets, then press a key after each target (Esc saves and exits)
4. Create inputs under **Edit Inputs** or prepare a CSV batch file
5. Select a recording and preset (or CSV), then click **Apply**

## Project layout

```
DataEntryAutonoma/
  dataEntryAutonoma.ahk   # Main application
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

- After each click during recording, press any key (except Esc) to mark the variable step
- A persistent tooltip shows **Esc to save and exit** while recording
- During apply, tooltips show **Assigned Var 1**, **Assigned Var 2**, etc.
- Esc stops recording, playback, or an entire CSV batch

## License

Copyright © Jayrr Dev. All rights reserved.
