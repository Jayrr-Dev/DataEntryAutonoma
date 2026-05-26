# Data Entry Autonoma

**Human-friendly, simple desktop automation for repetitive data entry.**

**By [Jayrr Dev](https://github.com/Jayrr-Dev)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Record mouse clicks, scrolls, and keyboard input once, then run the same workflow again with different values from a preset or CSV file. No scripting required: click **Record**, do your task, click **Run**. Built with AutoHotkey v2 for Windows.

## What it does

Data Entry Autonoma is a human-friendly, simple desktop tool for repeating structured input across apps and forms. You perform a workflow once while the app records it, then replay that workflow with different text values from a preset or a CSV file. The interface stays small and clear: two main buttons, three tabs, and plain-language tooltips while you work.

Typical uses:

- Filling the same form many times with different names, IDs, amounts, or notes
- Running one recorded workflow across dozens or hundreds of CSV rows overnight or in batches
- Automating click, scroll, and type sequences in legacy desktop software
- Saving repeatable UI paths (tabs, buttons, fields) without writing a custom script each time
- Mixing click-only steps (navigation) with typed variable fields (data entry)

## Features

### Recording

- **Record** button starts a capture session for clicks, scrolls, and optional keystrokes
- **Click targets** store screen coordinates, window client coordinates, and percentage positions inside the target window
- **Window matching** uses hwnd, class, title, and exe so replay can find the right window again
- **Scroll capture** records wheel direction, delta, and notch count at the cursor position
- **Variable keys** are created only when you press a key after a click; click-only steps replay as clicks with no typing
- **Shift-hold delays** let you insert manual pauses during recording; a live tooltip at the cursor shows seconds held
- **Esc saves** the recording and opens a rename dialog; **Cancel** on that dialog discards the file
- **Edit Log** opens the raw recording file for advanced edits
- **Rename** and **Delete** for recordings from the Recordings tab
- Recordings list shows **name** and **variable count** for each session

### Run (replay)

- **Run** button replays the selected recording using a preset or CSV batch
- **Smooth** or **Instant** mouse movement
- **Human-like** or **Instant** typing with configurable speeds
- **Preset pauses only** or **Recorded gaps** for timing between steps
- **Initial delay**, **click pause**, and **step pause** controls in milliseconds
- **Assigned Var N** tooltips during run show which variable slot is active
- **Esc** stops a single run or an entire CSV batch
- User mouse input can be blocked during run to avoid accidental interference

### Presets (Input Presets tab)

- Save named preset files with speeds, pauses, run options, and variable text values
- **Edit Preset** for full control over timing and variables
- **Delete Preset** and **Refresh** list buttons
- Selecting a preset loads its mouse and typing options into the **Run Options** tab
- One value per line in the preset maps to `variable-1`, `variable-2`, and so on

### CSV batch

- Optional CSV file runs the same recording once per row with different values
- Column 1 is a row label (status display only)
- Columns 2 and onward map to `variable-1`, `variable-2`, etc.
- Preset is optional during batch run: row values replace preset variables; preset still supplies speeds and run options if selected
- **Browse** to pick a CSV path; **i** button opens in-app help
- Blank lines and lines starting with `#` are ignored

### App behavior

- **Single instance**: only one app window at a time
- **Always on top** main window for quick access
- Remembers last selected recording, preset, and CSV in `apply-state.ini`
- **Standalone exe** via `compile.ps1`; end users do not need AutoHotkey installed
- Open source under MIT with required attribution (see [License & attribution](#license--attribution))

## Main window

| Area | Purpose |
|------|---------|
| **Status bar** | Current action, selection summary, batch progress |
| **Recordings** tab | Pick, rename, edit log, or delete recordings |
| **Input Presets** tab | Pick presets, CSV batch path, edit/delete presets |
| **Run Options** tab | Smooth/Instant mouse and Human-like/Instant typing for the next run |
| **Record** | Start a new capture session |
| **Run** | Replay the selected recording |

## Quick start

1. Clone this repository
2. Run `dataEntryAutonoma.ahk`
3. Click **Record**, perform your workflow (clicks, scrolls, keys where needed)
4. Press **Esc** to save; enter a name or click **Cancel** to discard
5. Open **Input Presets**, click **Edit Preset**, add your variable values and timing
6. Select a recording and preset, then click **Run**

For many rows, prepare a CSV file instead of typing variables into a preset.

## Recording workflow

1. Click **Record**. The main window hides so you can work in other apps.
2. Click targets in your app. After each click you may press a key to mark typed input for that field, or skip the key for click-only navigation.
3. Scroll when needed; wheel actions are captured at the cursor.
4. Hold **Shift** to add a delay. Release Shift to confirm (minimum 0.2 seconds). The delay tooltip follows your cursor.
5. Press **Esc** when finished. Name the recording in the dialog or click **Cancel** to throw it away.
6. Close the app window while recording to cancel without saving.

Corner tooltip while recording: **Esc = Save · Hold Shift = delay**

## Run workflow

1. Select a recording on the **Recordings** tab.
2. Select a preset on **Input Presets**, or set a CSV batch path, or both (CSV values override preset variables).
3. Adjust **Run Options** if needed (mouse and typing style).
4. Click **Run**. The app moves the mouse, clicks, scrolls, and types according to the recording and preset.
5. Press **Esc** to stop.

If the recording expects typed variables but none are provided, the app prompts you to use **Edit Preset** or a CSV file.

## Preset settings reference

| Setting | Description |
|---------|-------------|
| Run speed | Multiplier for recorded gap timing when **Recorded gaps** is enabled |
| Typing speed | Multiplier for per-key delay during human-like typing |
| Move speed | Multiplier for smooth mouse travel time |
| Initial delay (ms) | Wait before the first action |
| Click pause (ms) | Pause after moving to a target, before the click |
| Step pause (ms) | Pause after each target before the next step |
| Preset pauses only | Uses your pause values; ignores elapsed time between recorded steps |
| Recorded gaps | Replays time gaps captured during recording (including Shift delays) |
| Smooth / Instant mouse | Curved movement vs teleport |
| Human-like / Instant typing | Randomized key timing vs immediate send |
| Variable inputs | One line per variable slot |

Default preset file format (saved under `saved-inputs/`):

```ini
playback_speed=1.0
typing_speed=1.0
move_speed=1.5
initial_delay=1000
click_pause_ms=150
segment_pause_ms=200
use_recorded_timing=0
smooth_mouse=1
human_typing=1
Alice
100
East
```

## CSV batch format

Each row runs one full pass through the selected recording:

```csv
1,Alice,100,East
2,Bob,250,West
```

Single-value row (maps to `variable-1` only):

```csv
hello
another row
```

Rules:

- Column 1 is a label shown in the status bar during batch run
- Columns 2+ map to `variable-1`, `variable-2`, `variable-3`, ...
- Lines starting with `#` and blank lines are ignored
- **Esc** stops the whole batch; completed rows stay completed

## Recording file format

Recordings are UTF-8 log files in `recordings/` (default prefix `di-`). They store pipe-delimited events for clicks, scrolls, keys, metadata, and manual delays. Coordinates prefer window percentage positions so replay survives window resize when possible.

You can inspect or edit a log with **Edit Log** on the Recordings tab.

## Requirements

| Use case | Requirement |
|----------|-------------|
| Development | [AutoHotkey v2](https://www.autohotkey.com/) |
| End users | `DataEntryAutonoma.exe` only (see [BUILD.md](BUILD.md)) |

Windows only.

## Project layout

```
DataEntryAutonoma/
  dataEntryAutonoma.ahk   # Main application
  LICENSE                 # MIT license (attribution required)
  compile.ps1             # Build standalone exe
  build.bat               # Build shortcut
  BUILD.md                # Detailed build and distribution guide
  assets/                 # App icon (SVG and ICO)
  recordings/             # Session logs (di-*.log)
  saved-inputs/           # Variable presets (*.txt)
  apply-state.ini         # Last selected recording, preset, CSV (auto-created)
  dist/                   # Compiled exe output (after build)
```

## Build executable

From the project root:

```powershell
.\compile.ps1
```

Output: `dist\DataEntryAutonoma.exe`

See [BUILD.md](BUILD.md) for distribution layout and prerequisites.

## Keyboard shortcuts

| Key | While recording | While running / CSV batch |
|-----|-----------------|---------------------------|
| **Esc** | Save (opens name dialog) | Stop run or batch |
| **Shift** (hold) | Add timed delay | (no effect) |

Cancel on the save dialog discards the recording. Closing the app window while recording also cancels without saving.

## License and attribution

This project is **open source** under the [MIT License](LICENSE).

You may use, modify, and distribute this software freely, but **you must give credit to Jayrr Dev**:

1. Keep the [LICENSE](LICENSE) file and copyright notice in all copies or substantial portions of the software.
2. Include attribution in documentation, about screens, or README when you redistribute or build on this project. For example:

   > Based on [Data Entry Autonoma](https://github.com/Jayrr-Dev/DataEntryAutonoma) by [Jayrr Dev](https://github.com/Jayrr-Dev).

The MIT license legally requires the copyright and permission notice to remain intact. The attribution above is the expected way to credit the original author.

## Author

**Jayrr Dev** · [github.com/Jayrr-Dev](https://github.com/Jayrr-Dev)
