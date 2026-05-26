# Data Entry Autonoma

**Human-friendly, simple desktop automation for repetitive data entry, including automated text input.**

**By [Jayrr Dev](https://github.com/Jayrr-Dev)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Show the app what to do once. It remembers your mouse clicks, scrolls, and keypresses, then repeats those same actions for you automatically, including typing text into fields for you.

Record mouse clicks, scrolls, and keyboard input once, then click **Run** to replay that exact sequence. The app can **automatically type text** into the fields you marked during recording, using values from a preset or CSV file so each run can enter different names, numbers, and notes without you typing them again. No scripting required.

**End users:** run `DataEntryAutonoma.exe`. **AutoHotkey does not need to be installed** on your PC. The exe is a standalone Windows app.

**Developers:** the source is built with [AutoHotkey v2](https://www.autohotkey.com/) and compiled into that exe.

## What it does

Data Entry Autonoma works like showing someone how to fill out a form, then having them do it again for you.

1. Click **Record** and use your mouse and keyboard normally: click buttons, scroll lists, type in fields (or press a key after a click to mark a field for automated text input later).
2. The app saves every click, scroll, and keypress as a replayable sequence.
3. Click **Run** and it performs those same actions automatically: moves the mouse, clicks, scrolls, and **types text for you** into the fields you set up during recording.
4. Store the text to type in a **preset** or **CSV file**. Each run or each CSV row can fill the form with new values while you watch or walk away.

You are not writing automation code. You are demonstrating the task once; the app plays it back like a macro and handles the typing for you. The interface stays small and clear: two main buttons, three tabs, and plain-language tooltips while you work.

Typical uses:

- Automatically typing names, IDs, amounts, or notes into the same form over and over
- Filling the same form many times with different values from a preset or CSV
- Running one recorded workflow across dozens or hundreds of CSV rows overnight or in batches
- Automating click, scroll, and type sequences in legacy desktop software
- Saving repeatable UI paths (tabs, buttons, fields) without writing a custom script each time
- Mixing click-only steps (navigation) with typed variable fields (data entry)

## Features

### Recording

- **Record** button starts a capture session for clicks, scrolls, and optional keystrokes
- **Click targets** store screen coordinates, window client coordinates, percentage positions inside the target window, and the mouse button used (left, right, or middle)
- **Window matching** uses hwnd, class, title, and exe so replay can find the right window again
- **Scroll capture** records wheel direction, delta, and notch count at the cursor position
- **Variable keys** are created only when you press a key after a click; click-only steps replay as clicks with no typing
- **Left-click hold and drag** records mouse button down, optional drag, and release (useful for Excel range selection); quick taps stay clicks, longer holds or drags are saved on release
- **Keyboard shortcuts** with Ctrl, Shift, or Alt are recorded and replayed (for example Ctrl+C, Shift+F10)
- **Esc saves** the recording and opens a rename dialog; **Cancel** on that dialog discards the file
- **Edit Log** opens the raw recording file for advanced edits
- **Rename** and **Delete** for recordings from the Recordings tab
- Recordings list shows **name** and **variable count** for each session

### Run (replay)

- **Run** button replays the selected recording using either an input preset **or** a CSV bulk batch (not both at once)
- **Smooth** or **Instant** mouse movement
- **Human-like** or **Instant** typing with configurable speeds
- **Preset pauses only** or **Recorded gaps** for timing between steps
- **Initial delay**, **click pause**, and **step pause** controls in milliseconds
- **Assigned Var N** tooltips during run show which variable slot is active
- **Esc** stops a single run or an entire CSV batch
- User mouse input can be blocked during run to avoid accidental interference

### Presets (Input Presets tab)

- Choose **Use input preset for Run** as the run input source
- Save named preset files with speeds, pauses, run options, and variable text values
- **Edit Preset**, **Delete Preset**, and **Refresh** list buttons
- Selecting a preset loads its mouse and typing options into the **Run Options** tab
- One value per line in the preset maps to `variable-1`, `variable-2`, and so on

### CSV bulk inputs (CSV Bulk Inputs tab)

- Choose **Use CSV bulk inputs for Run** as the run input source (mutually exclusive with presets)
- Saved CSV files live in `csv-batches\`; **Edit CSV**, **Rename**, **Delete**, **Browse**, and **Refresh**
- **Browse** can load an external CSV; optional import copies it into `csv-batches\`
- **Config** (next to the run-source radio) sets **Ask to run next line** or **Run all rows automatically**
- CSV file runs the same recording once per row with different values
- Column 1 is a row label (status display only)
- Columns 2 and onward map to `variable-1`, `variable-2`, etc.
- **i** button opens in-app help; step-by-step mode shows a progress table (all variable columns) and per-row Run / Skip / Run all remaining prompts
- Blank lines and lines starting with `#` are ignored

### App behavior

- **Single instance**: only one app window at a time
- **Always on top** main window for quick access
- Remembers last selected recording, preset, and CSV in `apply-state.ini`
- **Standalone exe** via `compile.ps1`; end users do not need AutoHotkey installed
- Open source under MIT with required attribution (see [License and attribution](#license-and-attribution))

## Main window

| Area | Purpose |
|------|---------|
| **Status bar** | Current action, selection summary, batch progress |
| **Recordings** tab | Pick, rename, edit log, or delete recordings |
| **Input Presets** tab | Pick presets; edit/delete presets; choose preset as run input source |
| **CSV Bulk Inputs** tab | Manage CSV files in `csv-batches\`; choose CSV as run input source |
| **Run Options** tab | Smooth/Instant mouse and Human-like/Instant typing for the next run |
| **Record** | Start a new capture session |
| **Run** | Replay the selected recording |

## Installation

Windows only. **AutoHotkey is not required** to run the app.

### Download the release zip (recommended)

1. Open [GitHub Releases](https://github.com/Jayrr-Dev/DataEntryAutonoma/releases) for **Data Entry Autonoma**.
2. Download **`DataEntryAutonoma-v1.0.3-win64.zip`** (or the latest release asset for your version).
3. Extract the ZIP to a folder, for example `%LOCALAPPDATA%\Programs\DataEntryAutonoma` or `C:\Tools\DataEntryAutonoma`.
4. Double-click **`DataEntryAutonoma.exe`** to run, or use **`runInstallWizard.bat`** from the extracted folder for guided setup.

The release zip includes the standalone exe, `assets\dataEntryAutonoma.ico`, empty `recordings\`, `saved-inputs\`, and `csv-batches\` folders, the install and uninstall wizard scripts, `README.md`, `CHANGELOG.md`, and `LICENSE`. You do **not** need to install AutoHotkey or clone the repository.

**Upgrading:** Run the install wizard again and choose the same install folder. The wizard overwrites the app files but keeps your `recordings\`, `saved-inputs\`, and `csv-batches\` data.

---

### Install wizard (optional)

If you already extracted the release zip (or cloned the repo for development), you can use the setup wizard instead of running the exe directly.

1. Open the folder that contains **`runInstallWizard.bat`** (from the extracted release zip or a local clone).
2. Double-click **`runInstallWizard.bat`**, or from PowerShell in that folder:
   ```powershell
   .\runInstallWizard.ps1
   ```
3. Follow the on-screen steps:
   - **Welcome** → **Install location** → **Shortcuts**
   - If the app files are not already in the folder, the wizard downloads them automatically when you click **Next**
   - Default install folder: `%LOCALAPPDATA%\Programs\DataEntryAutonoma`
4. Click **Install**, then **Close** when setup completes.

**Standalone only:** The wizard installs `DataEntryAutonoma.exe`. **AutoHotkey is not required** on the PC where you install or run the app.

**Developers only:** If you cloned the repo and have AutoHotkey v2 with compiler, use **Build exe (developers)** on the Application file step. End users should browse for a downloaded exe instead.

The wizard creates `recordings\`, `saved-inputs\`, and `csv-batches\` folders and optional shortcuts for you.

**Reinstalling or upgrading:** If you point the wizard at a folder that already contains `DataEntryAutonoma.exe`, it upgrades in place. Your recordings, presets, and CSV files in `recordings\`, `saved-inputs\`, and `csv-batches\` are preserved; the exe, assets, LICENSE, README, and wizard scripts are overwritten. It also copies `runUninstallWizard.bat` and `runUninstallWizard.ps1` into the install folder.

---

### Uninstall wizard (optional)

To remove the app, shortcuts, and optional user data:

1. Run **`runUninstallWizard.bat`** from the install folder (or from an extracted release zip / repo clone).
2. Choose the install folder (default: `%LOCALAPPDATA%\Programs\DataEntryAutonoma`).
3. Select what to remove (application files, recordings, presets, CSV bulk inputs, `apply-state.ini`, shortcuts).
4. Confirm on the summary step, then click **Uninstall**.

If you run the uninstaller from inside the install folder, remaining files (including the uninstaller itself) are deleted automatically after the wizard closes.

---

### Manual installation

Use **Path 1** if you just want to run the app. Use **Path 2** if you are developing or running from source. Use **Path 3** only if you need to build the standalone `.exe` yourself.

### Path 1: End user (standalone `.exe`, recommended)

**AutoHotkey is not required.** The exe runs on its own.

1. **Get the app files**
   - Download the release zip or `DataEntryAutonoma.exe` from [github.com/Jayrr-Dev/DataEntryAutonoma](https://github.com/Jayrr-Dev/DataEntryAutonoma), or copy the exe from another PC.
   - You do **not** need to install AutoHotkey on this computer.

2. **Create a folder** for the app, for example:
   ```
   C:\Tools\DataEntryAutonoma\
   ```

3. **Copy these items** into that folder:
   ```
   DataEntryAutonoma.exe
   recordings\          (can be an empty folder)
   saved-inputs\        (can be an empty folder)
   ```
   The app can create `recordings` and `saved-inputs` on first run if they are missing, but including empty folders keeps the layout clear.

4. **Run the app**
   - Double-click `DataEntryAutonoma.exe`.
   - The main window opens and stays on top. A tray icon also appears.

5. **First launch check**
   - You should see tabs: **Recordings**, **Input Presets**, **CSV Bulk Inputs**, **Run Options**.
   - You should see **Record** and **Run** at the bottom.
   - Status bar should show **Ready**.

6. **Optional: CSV bulk inputs**
   - Saved CSV files live in `csv-batches\` (created automatically). Use the **CSV Bulk Inputs** tab to edit, rename, delete, or browse for a file.

**Windows SmartScreen:** If Windows warns about an unknown publisher, that is common for unsigned executables. Only continue if you trust the source (this repo or your own build).

---

### Path 2: Developer (run the `.ahk` script)

Use this path to run the latest source code or contribute changes.

1. **Install AutoHotkey v2**
   - Download from [autohotkey.com](https://www.autohotkey.com/).
   - Install the **v2** release (not v1.1).
   - Default install includes `AutoHotkey64.exe` used to run `.ahk` scripts.

2. **Get the source code**

   **Option A: Git clone**
   ```powershell
   git clone https://github.com/Jayrr-Dev/DataEntryAutonoma.git
   cd DataEntryAutonoma
   ```

   **Option B: Download ZIP**
   - On GitHub, click **Code** → **Download ZIP**.
   - Extract the ZIP to a folder such as `C:\Dev\DataEntryAutonoma`.

3. **Open the project folder**
   - The main script is `dataEntryAutonoma.ahk` in the project root.
   - Keep the whole folder together. The script expects `recordings\`, `saved-inputs\`, and `assets\` beside it.

4. **Run the script**
   - Double-click `dataEntryAutonoma.ahk`, or
   - Right-click → **Run with AutoHotkey v2**, or
   - From PowerShell in the project folder:
     ```powershell
     & "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\dataEntryAutonoma.ahk"
     ```

5. **Confirm it works**
   - The **Data Entry Autonoma** window opens.
   - Folders `recordings` and `saved-inputs` are created automatically if missing.

6. **Reload after edits**
   - Right-click the tray icon → **Reload Script** when you change the `.ahk` file.

**Wrong version error:** If you see errors about `#Requires AutoHotkey v2.0`, you are running v1.1 or an old runner. Install and use AutoHotkey **v2**.

---

### Path 3: Build the standalone `.exe` (optional)

For maintainers or anyone packaging the app for others. Requires AutoHotkey v2 with the compiler (Ahk2Exe).

1. **Install AutoHotkey v2** with compiler support from [autohotkey.com](https://www.autohotkey.com/).

2. **Check default paths** (edit `compile.ps1` if yours differ):
   - `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`
   - `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`

3. **Open PowerShell** in the project root (the folder that contains `dataEntryAutonoma.ahk`).

4. **Run the build**
   ```powershell
   .\compile.ps1
   ```
   Or double-click `build.bat`.

5. **Find the output**
   - Built file: `dist\DataEntryAutonoma.exe`
   - Copy that exe plus empty `recordings` and `saved-inputs` folders when sharing with others (same layout as Path 1).

6. **If PowerShell blocks the script**
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
   Then run `.\compile.ps1` again. Only do this if you trust this project’s scripts.

More build and packaging notes: [BUILD.md](BUILD.md).

---

### Where your data is stored

All paths are relative to the app folder (next to the `.exe` or `.ahk`):

| File or folder | Purpose |
|----------------|---------|
| `recordings\` | Saved recording logs (`di-*.log`) |
| `saved-inputs\` | Preset files with speeds, options, and variable text |
| `csv-batches\` | Saved CSV bulk input files (`*.csv`) |
| `apply-state.ini` | Last selected recording, preset, CSV, and run input source (auto-created) |

---

### Installation troubleshooting

| Problem | What to try |
|---------|-------------|
| Script will not start | Install AutoHotkey **v2**, not v1.1 |
| `Ahk2Exe not found` when building | Reinstall AutoHotkey v2 or fix paths at the top of `compile.ps1` |
| Save dialog hidden after recording | Update to the latest script; the app shows the main window before the name dialog |
| App closes when I close the window during recording | Expected: closing the window cancels the recording |
| Only one instance allowed | By design. Close the existing window or tray instance first |
| Recordings or presets missing after move | Move the whole folder together. Do not move only the `.exe` without its data folders |

---

## Quick start

After [installation](#installation):

1. Run `dataEntryAutonoma.ahk` or `DataEntryAutonoma.exe`
2. Click **Record**, perform your workflow (clicks, scrolls, keys where needed)
3. Press **Esc** to save; enter a name or click **Cancel** to discard
4. Open **Input Presets**, click **Edit Preset**, add your variable values and timing — **or** use **CSV Bulk Inputs** for many rows
5. Select a recording, choose **Input preset** or **CSV bulk inputs** as the run source, then click **Run**

For many rows, create or import a CSV on the **CSV Bulk Inputs** tab instead of typing variables into a preset.

## Recording workflow

1. Click **Record**. The main window hides so you can work in other apps.
2. Click targets in your app. After each click you may press a key to mark typed input for that field, or skip the key for click-only navigation.
3. Scroll when needed; wheel actions are captured at the cursor.
4. **Drag** or **hold left-click** to record a mouse hold (for example to select cells in Excel), then release to save it. Quick clicks stay normal clicks.
5. Press **Ctrl**, **Shift**, or **Alt** with another key to record keyboard shortcuts (for example Ctrl+C).
6. Press **Esc** when finished. Name the recording in the dialog or click **Cancel** to throw it away.
7. Close the app window while recording to cancel without saving.

Corner tooltip while recording: **Esc = Save · Click = click · Hold or drag = mouse hold**

## Run workflow

1. Select a recording on the **Recordings** tab.
2. On **Input Presets**, choose **Use input preset for Run** and pick a preset — **or** on **CSV Bulk Inputs**, choose **Use CSV bulk inputs for Run** and pick a CSV file.
3. Adjust **Run Options** if needed (mouse and typing style).
4. Click **Run**. The app moves the mouse, clicks, scrolls, and types according to the recording and your selected input source.
5. Press **Esc** to stop.

If the recording expects typed variables but none are provided, the app prompts you to use **Edit Preset** or a CSV file on **CSV Bulk Inputs**.

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
| Recorded gaps | Replays time gaps captured during recording (including right-click hold delays) |
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
- **Config** (CSV Bulk Inputs tab) sets run mode: **Ask to run next line** shows a progress table with all variable columns; before each row you can Run, Skip, or Run all remaining. **Run all rows automatically** skips prompts.
- **Esc** stops the whole batch; completed rows stay completed

## Recording file format

Recordings are UTF-8 log files in `recordings/` (default prefix `di-`). They store pipe-delimited events for clicks, scrolls, keys, metadata, and manual delays. Coordinates prefer window percentage positions so replay survives window resize when possible.

You can inspect or edit a log with **Edit Log** on the Recordings tab.

## Does the exe need AutoHotkey installed?

**No.** If you use `DataEntryAutonoma.exe`, you do **not** need AutoHotkey installed on that computer.

| What you run | AutoHotkey required? | Notes |
|--------------|----------------------|-------|
| **`DataEntryAutonoma.exe`** | **No** | Standalone app. The AutoHotkey runtime is bundled inside the exe when it is compiled. Works on a clean Windows PC. |
| **`dataEntryAutonoma.ahk`** (source script) | **Yes** | For development only. Requires [AutoHotkey v2](https://www.autohotkey.com/) installed. |

When you build the exe with `compile.ps1`, Ahk2Exe packages the script and interpreter into one file. End users only need Windows 10 or 11 and the exe (plus optional `assets\`, `recordings\`, and `saved-inputs\` folders).

**Quick test on a PC without AutoHotkey:** copy `DataEntryAutonoma.exe` to the machine, double-click it, and the main window should open. No install step for AutoHotkey is involved.

## Requirements

| Use case | Requirement |
|----------|-------------|
| Easiest install | Windows 10 or 11, run [Install wizard](#easiest-install-wizard-recommended) |
| End users | Windows 10 or 11, `DataEntryAutonoma.exe` ([Installation Path 1](#path-1-end-user-standalone-exe-recommended)) |
| Developers | Windows 10 or 11, [AutoHotkey v2](https://www.autohotkey.com/) ([Installation Path 2](#path-2-developer-run-the-ahk-script)) |
| Building the exe | AutoHotkey v2 with Ahk2Exe ([Installation Path 3](#path-3-build-the-standalone-exe-optional)) |

See [Installation](#installation) for full step-by-step instructions.

## Version history

Release notes are in [CHANGELOG.md](CHANGELOG.md).

| Version | Highlights |
|---------|------------|
| **1.0.3** | CSV Bulk Inputs tab, preset vs CSV run source, mouse hold/drag + hotkey recording fixes, all CSV variables in batch UI |
| **1.0.2** | CSV Config with ask next line, batch progress table, uninstall wizard in release zip |
| **1.0.1** | Install wizard upgrades existing installs in place; version shown in app title |
| **1.0.0** | Initial release: Record/Run, presets, CSV batch, install wizard, standalone exe |

## Project layout

```
DataEntryAutonoma/
  dataEntryAutonoma.ahk   # Main application
  runInstallWizard.ps1    # Graphical install wizard
  runInstallWizard.bat    # Double-click to run the wizard
  runUninstallWizard.ps1  # Graphical uninstall wizard
  runUninstallWizard.bat  # Double-click to run the uninstaller
  LICENSE                 # MIT license (attribution required)
  CHANGELOG.md            # Release notes
  VERSION                 # Current version (read by packageRelease.ps1)
  compile.ps1             # Build standalone exe
  build.bat               # Build shortcut
  BUILD.md                # Detailed build and distribution guide
  assets/                 # App icon (SVG and ICO)
  recordings/             # Session logs (di-*.log)
  saved-inputs/           # Variable presets (*.txt)
  csv-batches/            # Saved CSV bulk input files (*.csv)
  apply-state.ini         # Last selected recording, preset, CSV (auto-created)
  dist/                   # Compiled exe output (after build)
```

## Build executable

If you already followed [Path 3 in Installation](#path-3-build-the-standalone-exe-optional), you have the exe at `dist\DataEntryAutonoma.exe`.

Quick command from the project root:

```powershell
.\compile.ps1
```

See [BUILD.md](BUILD.md) for distribution layout and advanced compile options.

## Keyboard shortcuts

| Key | While recording | While running / CSV batch |
|-----|-----------------|---------------------------|
| **Esc** | Save (opens name dialog) | Stop run or batch |
| **Left-click** (hold or drag) | Record mouse hold/drag, release to save | Replays button down, drag or wait, button up |
| **Ctrl/Shift/Alt + key** | Record shortcut | Replays shortcut |

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
