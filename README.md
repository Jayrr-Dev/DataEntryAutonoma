# Data Entry Autonoma

**Human-friendly desktop automation for repetitive data entry, including automated text input.**

**By [Jayrr Dev](https://github.com/Jayrr-Dev)**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Show the app what to do once. It remembers your mouse clicks, scrolls, and keypresses and repeats those same actions for you automatically, including typing text into fields for you.

**Record** captures mouse clicks, scrolls, and keyboard input as a replayable sequence. **Run** replays that exact sequence. The app can **automatically type text** into the fields you marked during recording, using values from a data input or CSV file so each run can enter different names, numbers, and notes without you typing them again. No scripting required.

**End users:** run `DataEntryAutonoma.exe`. **AutoHotkey does not need to be installed** on your PC. The exe is a standalone Windows app.

**Developers:** the source is built with [AutoHotkey v2](https://www.autohotkey.com/) and compiled into that exe.

**Current release:** v1.3.0

## What it does

Data Entry Autonoma works like showing someone how to fill out a form and having them do it again for you.

1. Click **Record** and use your mouse and keyboard normally: click buttons, scroll lists, type in fields (or press a key after a click to mark a field for automated text input later).
2. The app saves every click, scroll, and keypress as a replayable sequence.
3. Click **Run** and it performs those same actions automatically: moves the mouse, clicks, scrolls, and **types text for you** into the fields you set up during recording.
4. Store the text to type in a **data input** or **CSV file**. Each run or each CSV row can fill the form with new values while you watch or walk away.

You are not writing automation code. You are demonstrating the task once; the app plays it back like a macro and handles the typing for you. The interface stays small and clear: two main buttons, five tabs, **Share** and **Import** on the title row, tab-specific **i** help buttons, list hover tooltips, and plain-language guidance while you work.

## What's new (v1.3.0)

- **Edit Hotkeys:** PgUp toggles Record start/save; Esc saves while recording; PgDn pause/resume; arrow keys Run forward/reverse (Left rewinds while paused)
- **Mouse hold/drag replay:** full drawn paths (circles, drags) replay correctly; **Hold speed** on Speed Settings
- **Save Recording** dialog with variable labels; default name from target window title
- **Label sync:** blue synced labels + `Sync from {recording}` tooltip in Edit Data Input / Edit CSV; merged labels at Run time
- **Double-click Name** on list rows to open Edit Log, Edit Data Input, or Edit CSV

See [Version history](#version-history) for v1.2.0 and earlier.

## What's new (v1.2.0)

- **Edit Recording Log → Global Adjust tab:** offset X/Y at Run, screen `w/h → w/h` rescale, target window apply to all events
- **Target title picker:** choose from open windows (↻ refresh); per-row window title and exe on click rows

See [Version history](#version-history) for v1.1.2 and earlier.

## What's new (v1.1.2)

- **Edit Data Input:** inline table editing, auto comma escaping, full-width columns
- **Bulk Inputs:** separate **Create CSV** and **Edit** buttons; larger CSV editor
- **Default move speed:** 10
- **Install:** `runDataEntryAutonoma.bat` unblocks and launches; release build validates exe version

See [Version history](#version-history) for v1.1.1 and earlier.

## What's new (v1.1.1)

- **Install wizard:** downloads automatically on welcome, clearer errors when source code vs release zip is used, optional build-from-source
- **Publish script:** `publishRelease.bat` builds and uploads the release zip to GitHub in one step
- **Install wizard UI:** fixed clipped welcome text and PowerShell errors on first run

See [Version history](#version-history) for v1.1.0 and earlier.

## What's new (v1.1.0)

- **CSV table editor:** edit saved CSV files in a ListView with inline cell edit, add/delete rows and columns, and Excel-style column headers
- **Share / Import bundles:** export or import portable folders or `.dea.zip` files with a `manifest.json` (recording plus data input or CSV)
- **Import and Share buttons** on the main window title row (right-aligned)
- **List hover tooltips** for recording and data input descriptions
- **Five-tab layout:** Recordings, Data Inputs, Bulk Inputs, Run Options, and Speed Settings (speed multipliers moved out of the data input editor)
- **Edit Data Input** and **Edit Recording Log** UI improvements; help text rewritten on all tabs (sectioned and concise)
- **Default move speed** is now 3 (was 1.5)

See [Version history](#version-history) and [CHANGELOG.md](CHANGELOG.md) for full release notes.

Typical uses:

- Automatically typing names, IDs, amounts, or notes into the same form over and over
- Filling the same form many times with different values from a data input or CSV
- Running one recorded workflow across dozens or hundreds of CSV rows overnight or in batches
- Automating click, scroll, and type sequences in legacy desktop software
- Saving repeatable UI paths (tabs, buttons, fields) without writing a custom script each time
- Mixing click-only steps (navigation) with typed variable fields (data entry)
- Sharing a recording plus its data input or CSV with a teammate via a bundle folder or zip

## Features

### Recording

- **Record** button starts a capture session for clicks, scrolls, and optional keystrokes
- **Click targets** store screen coordinates, window client coordinates, percentage positions inside the target window, and the mouse button used (left, right, or middle)
- **Window matching** uses hwnd, class, title, and exe so replay can find the right window again
- **Scroll capture** records wheel direction, delta, and notch count at the cursor position
- **Variable keys** are created when you type a character after a click; click-only steps replay as clicks with no typing
- **Hold Caps Lock** to record a manual delay between steps (Caps Lock is suppressed while recording)
- **Left-click hold and drag** records mouse button down, optional drag, and release (useful for Excel range selection); quick taps stay clicks, longer holds or drags are saved on release
- **Keyboard shortcuts** with Ctrl, Shift, or Alt are recorded and replayed (for example Ctrl+C, Shift+F10)
- **Hotkey feedback** beside the cursor while recording (for example `Hotkey: Ctrl + c`)
- **Esc saves** the recording and opens a rename dialog; **Cancel** on that dialog discards the file
- Recordings list shows **name** and **variable count** for each session; hover a row to preview its optional description
- **Rename**, **Edit Log**, and **Delete** from the Recordings tab

### Edit Recording Log

Open **Edit Log** on the Recordings tab to adjust a saved recording without re-recording.

**Description (top of window)** — optional notes stored in the log header; shown as a tooltip when you hover the recording in the list.

**Events tab**

- Table of every logged step: elapsed ms, type, optional label, and summary
- **Selected row** editor for timing and type-specific fields (click button, pct X/Y, variable name, scroll direction, and so on)
- Rich click rows also expose **Window title** and **Exe**; changing them clears a stale hwnd so Run matches by title/exe/class
- Optional row **Label** (`|note|…` in the file) is ignored during Run
- **Apply row** or double-click a row to commit edits; **Save** writes the table back to the log file

**Global Adjust tab**

Bulk fixes when replay lands on the wrong pixel or the wrong window (common on another monitor, RDP, or Citrix):

- **Offset (px): X / Y** — pixel nudge applied to every click at **Run**; saved in the log header when you **Save** (does not rewrite table rows by itself)
- **Screen: w / h → w / h** — rescale all click, scroll, and mouse-hold coordinates from the recorded client size toward a new size; **Apply to all clicks** rewrites Events tab rows
- **Target window** — set **title**, **exe**, and **class** for all events; pick from a dropdown of open windows (↻ refresh) or type manually; **Apply target window** updates every row and clears stale hwnd values
- Separate **i** help on Events and Global Adjust tabs

**Raw log tab** — read-only preview of the file that **Save** will write.

### Run (replay)

- **Run** button replays the selected recording using either a data input **or** a bulk CSV batch (not both at once)
- **Window matching** at replay uses title, exe, class, and hwnd from each click; percentage (client) coordinates scale when the target window is found
- Optional **playback offset** (`# playback_offset_x` / `# playback_offset_y` in the log header) nudges every click — set in **Edit Log → Global Adjust**
- **Smooth** or **Instant** mouse movement
- **Human-like** or **Instant** typing with configurable speeds
- **Fixed pauses only** or **Recorded gaps** for timing between steps
- **Initial delay**, **click pause**, and **step pause** controls in milliseconds
- **Assigned Var N** tooltips during run show which variable slot is active
- **Esc** stops a single run or an entire CSV batch
- User mouse input can be blocked during run to avoid accidental interference

### Data Inputs tab

- Choose **Use data input for Run** as the run input source
- Saved data inputs live in `saved-inputs\` as `*.txt` files
- **Add Data Input**, **Edit Data Input**, and **Delete Data Input** list buttons
- **Edit Data Input** opens a table editor for name, optional description (shown as a list tooltip), and variable values (slot, optional label, value)
- Optional **labels** on variable rows are for your notes only (`name:Alice` types `Alice`)
- One value per variable row maps to `variable-1`, `variable-2`, and so on
- **i** button opens in-app help for data inputs and run input source

### Bulk Inputs tab

- Choose **Use bulk inputs for Run** as the run input source (mutually exclusive with data inputs)
- Saved CSV files live in `csv-batches\`; **Create CSV**, **Edit**, **Rename**, **Delete**, **Browse**, and **Refresh**
- **Edit CSV** opens a table editor with inline cell edit, add/delete rows and columns, and Excel-style headers
- **Browse** can load an external CSV; optional import copies it into `csv-batches\`
- **Config** run mode: **Ask to run next line before each row** or **Run all rows automatically**
- CSV file runs the same recording once per row with different values
- Column 1 on data rows is a label shown in the status bar during batch run
- Row 1 is a header row with column labels for your notes (shown in batch progress and prompts)
- Columns 2+ on data rows map to `variable-1`, `variable-2`, etc.
- **i** button next to **Saved CSV files** opens format and batch help
- Blank lines and lines starting with `#` are ignored
- Step-by-step batch mode shows a progress table (all variable columns) and per-row Run / Skip / Run all remaining prompts

### Run Options tab

- **Smooth** or **Instant** mouse movement and **Human-like** or **Instant** typing for the next run
- **Click pause** and **Step pause** in milliseconds
- **Fixed pauses only** or **Recorded gaps** for between-step timing
- **i** button opens in-app help for playback style and pauses
- For speed multipliers and initial delay, use the **Speed Settings** tab

### Speed Settings tab

- **Run speed**, **Typing speed**, and **Move speed** multipliers (default move speed: 10)
- **Initial delay (ms)** before playback starts
- **i** button opens in-app help for speed fields
- Values apply to the next Run and are saved with data input files when you use **Edit Data Input**

### Share / Import bundles

- **Share** and **Import** buttons on the main window title row (right-aligned)
- **Share** exports the selected recording plus the active data input or CSV as a portable folder or `.dea.zip` file
- Bundle includes `manifest.json` listing the recording and data input or CSV files (not arbitrary extra files beside them)
- Default share name pattern: `{recording}-{data input or CSV}-{PC}-{date}`
- **Import** asks folder vs zip and pulls in the bundle's recording and data input or CSV

### In-app help

Each tab has an **i** button beside its section label. Click it for tab-specific guidance:

| Tab / dialog | Help covers |
|--------------|-------------|
| **Recordings** | Selecting recordings, Rename / Edit Log / Delete, recording tips (Esc, clicks, Caps Lock delay, hold/drag, shortcuts) |
| **Edit Log → Events** | Events table, selected row fields, labels, Apply row, Save |
| **Edit Log → Global Adjust** | Offset at Run, Screen w/h rescale, target window picker, Apply buttons |
| **Data Inputs** | Run input source, Add / Edit / Delete Data Input, variables, labels, data input vs bulk input exclusivity |
| **Bulk Inputs** | CSV format, `csv-batches\`, Edit CSV table editor, Config run mode, batch rules |
| **Run Options** | Smooth vs Instant mouse, Human-like vs Instant typing, click/step pauses, fixed vs recorded timing |
| **Speed Settings** | Run, typing, and move speed multipliers, initial delay |

There is no separate Help button; use the **i** on the tab you are working in.

### App behavior

- **Version in title:** window title shows the current release (for example `Data Entry Autonoma v1.3.0`)
- **Single instance**: only one app window at a time
- **Always on top** main window for quick access
- Remembers last selected recording, data input, and CSV in `apply-state.ini`
- **Standalone exe** via `compile.ps1`; end users do not need AutoHotkey installed
- **Install and uninstall wizards** for guided setup and removal
- Open source under MIT with required attribution (see [License and attribution](#license-and-attribution))

## Main window

| Area | Purpose |
|------|---------|
| **Title row** | App name, version, **Import** and **Share** buttons |
| **Status bar** | Current action, selection summary, batch progress |
| **Recordings** tab | Pick, rename, **Edit Log** (Events / Global Adjust / Raw log), or delete recordings; **i** for tab help |
| **Data Inputs** tab | Pick data inputs; add/edit/delete; choose data input as run source; **i** for tab help |
| **Bulk Inputs** tab | Manage CSV files in `csv-batches\`; Config run mode; choose bulk input as run source; **i** for tab help |
| **Run Options** tab | Mouse movement, typing style, and timing pauses for the next run; **i** for tab help |
| **Speed Settings** tab | Speed multipliers and initial delay for the next run; **i** for tab help |
| **Record** | Start a new capture session |
| **Run** | Replay the selected recording |

## Installation

Windows only. **AutoHotkey is not required** to run the app.

### Download the release zip (recommended)

1. Open [GitHub Releases](https://github.com/Jayrr-Dev/DataEntryAutonoma/releases) for **Data Entry Autonoma**.
2. Download **`DataEntryAutonoma-v1.3.0-win64.zip`** (or the latest release asset for your version).
3. Extract the ZIP to a folder, for example `%LOCALAPPDATA%\Programs\DataEntryAutonoma` or `C:\Tools\DataEntryAutonoma`.
4. Double-click **`DataEntryAutonoma.exe`** to run, or use **`runInstallWizard.bat`** from the extracted folder for guided setup.

The release zip includes the standalone exe, `assets\dataEntryAutonoma.ico`, empty `recordings\`, `saved-inputs\`, and `csv-batches\` folders, the install and uninstall wizard scripts, `README.md`, `CHANGELOG.md`, `VERSION`, and `LICENSE`. You do **not** need to install AutoHotkey or clone the repository.

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
   - **Welcome** shows version, data folders, and CSV/data input format tips
   - **Install location** → **Shortcuts and launch**
   - Shows install type (fresh or upgrade), version (including upgrade from/to), and target folder before you click **Install**
   - If the app files are not already in the folder, the wizard downloads them automatically when you click **Next**
   - Default install folder: `%LOCALAPPDATA%\Programs\DataEntryAutonoma`
4. Use **Install** to apply setup; **Close** dismisses the wizard.

**Standalone only:** The wizard installs `DataEntryAutonoma.exe`. **AutoHotkey is not required** on the PC where you install or run the app.

**Developers only:** If you cloned the repo and have AutoHotkey v2 with compiler, use **Build exe (developers)** on the Application file step. End users should browse for a downloaded exe instead.

The wizard creates `recordings\`, `saved-inputs\`, and `csv-batches\` folders and optional shortcuts for you.

**Reinstalling or upgrading:** If you point the wizard at a folder that already contains `DataEntryAutonoma.exe`, it upgrades in place. Your recordings, data inputs, and CSV files in `recordings\`, `saved-inputs\`, and `csv-batches\` are preserved; the exe, assets, LICENSE, README, CHANGELOG, VERSION, and wizard scripts are overwritten. It also copies `runUninstallWizard.bat` and `runUninstallWizard.ps1` into the install folder.

---

### Uninstall wizard (optional)

To remove the app, shortcuts, and optional user data:

1. Run **`runUninstallWizard.bat`** from the install folder (or from an extracted release zip / repo clone).
2. Choose the install folder (default: `%LOCALAPPDATA%\Programs\DataEntryAutonoma`). The wizard title and confirm step show the installed version when `VERSION` is present.
3. Select what to remove (application files including VERSION/CHANGELOG/wizards, recordings, data inputs, CSV bulk inputs, `apply-state.ini`, shortcuts).
4. On the summary step, click **Uninstall** to apply the selected removals.

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
   assets\              (optional but recommended for tray/window icons)
   recordings\          (can be an empty folder)
   saved-inputs\        (can be an empty folder)
   csv-batches\         (can be an empty folder)
   ```
   The app can create `recordings`, `saved-inputs`, and `csv-batches` on first run if they are missing, but including empty folders keeps the layout clear.

4. **Run the app**
   - Double-click `DataEntryAutonoma.exe`.
   - The main window opens and stays on top. A tray icon also appears.

5. **First launch check**
   - You should see tabs: **Recordings**, **Data Inputs**, **Bulk Inputs**, **Run Options**, **Speed Settings**.
   - You should see **Import** and **Share** on the title row, and **Record** and **Run** at the bottom.
   - Status bar should show **Ready**.

6. **Optional: bulk inputs**
   - Saved CSV files live in `csv-batches\` (created automatically). Use the **Bulk Inputs** tab to edit, rename, delete, or browse for a file.

**Windows SmartScreen:** If Windows warns about an unknown publisher, that is common for unsigned executables. Only continue if you trust the source (this repo or your own build). Choose **More info** → **Run anyway**.

**App will not open after download:** Extract the full zip first (do not run the exe from inside the zip). Then either run **`runDataEntryAutonoma.bat`** (unblocks and starts the app), or right-click **`DataEntryAutonoma.exe`** → **Properties** → check **Unblock** → **OK**, then open again. Check the taskbar for a SmartScreen dialog that may be behind other windows.

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
   - Keep the whole folder together. The script expects `recordings\`, `saved-inputs\`, `csv-batches\`, and `assets\` beside it.

4. **Run the script**
   - Double-click `dataEntryAutonoma.ahk`, or
   - Right-click → **Run with AutoHotkey v2**, or
   - From PowerShell in the project folder:
     ```powershell
     & "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\dataEntryAutonoma.ahk"
     ```

5. **Confirm it works**
   - The **Data Entry Autonoma** window opens.
   - Folders `recordings\`, `saved-inputs\`, and `csv-batches\` are created automatically if missing.

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
   - Package for distribution: `.\packageRelease.ps1` creates `release\DataEntryAutonoma-v1.3.0-win64.zip`
   - Publish to GitHub: `.\publishRelease.ps1` builds and uploads the zip
   - Copy the exe plus empty `recordings\`, `saved-inputs\`, and `csv-batches\` folders when sharing with others (same layout as Path 1).

6. **If PowerShell blocks the script**
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
   Rerun `.\compile.ps1` with the updated execution policy. Only do this if you trust this project's scripts.

More build and packaging notes: [BUILD.md](BUILD.md).

---

### Where your data is stored

All paths are relative to the app folder (next to the `.exe` or `.ahk`):

| File or folder | Purpose |
|----------------|---------|
| `recordings\` | Saved recording logs (`di-*.log`) |
| `saved-inputs\` | Data input files with variable text and saved run settings (`*.txt`) |
| `csv-batches\` | Saved CSV bulk input files (`*.csv`) |
| `apply-state.ini` | Last selected recording, data input, CSV, and run input source (auto-created) |

---

### Installation troubleshooting

| Problem | What to try |
|---------|-------------|
| Script will not start | Install AutoHotkey **v2**, not v1.1 |
| `Ahk2Exe not found` when building | Reinstall AutoHotkey v2 or fix paths at the top of `compile.ps1` |
| Save dialog hidden after recording | Update to the latest script; the app shows the main window before the name dialog |
| App closes when I close the window during recording | Expected: closing the window cancels the recording |
| Only one instance allowed | By design. Close the existing window or tray instance first |
| Recordings or data inputs missing after move | Move the whole folder together. Do not move only the `.exe` without its data folders |

---

## Quick start

After [installation](#installation):

1. Run `dataEntryAutonoma.ahk` or `DataEntryAutonoma.exe`
2. Click **Record**, perform your workflow (clicks, scrolls, keys where needed)
3. Press **Esc** to open the save dialog (name the recording or **Cancel** to discard)
4. On **Data Inputs**, click **Add Data Input** or **Edit Data Input** to set variable values, **or** on **Bulk Inputs**, create or pick a CSV for many rows
5. Adjust **Run Options** and **Speed Settings** if needed
6. Click **Run** with a recording and run input source selected (see [Run workflow](#run-workflow))
7. Click **i** on any tab if you need help with that section

For many rows, use **Bulk Inputs** instead of typing variables into a data input. Use **Config** on that tab to choose step-by-step prompts or automatic batch run.

## Recording workflow

1. Click **Record**. The main window hides so you can work in other apps.
2. Click targets in your app. After each click you may type a character to mark typed input for that field, or skip typing for click-only navigation.
3. Scroll when needed; wheel actions are captured at the cursor.
4. **Hold Caps Lock** to record a manual delay between steps.
5. **Drag** or **hold left-click** to record a mouse hold (for example to select cells in Excel). The hold is saved on release. Quick clicks stay normal clicks.
6. Press **Ctrl**, **Shift**, or **Alt** with another key to record keyboard shortcuts (for example Ctrl+C).
7. Press **Esc** when finished. The save dialog lets you name the recording (**Cancel** discards it).
8. Close the app window while recording to cancel without saving.

Corner tooltip while recording: **Esc = Save · Click = click · Hold Caps Lock = delay · Hold/drag LMB = hold**

## Run workflow

1. Select a recording on the **Recordings** tab.
2. Pick a run input source: a data input on **Data Inputs** or a CSV on **Bulk Inputs** (mutually exclusive).
3. Adjust **Run Options** (mouse, typing, pauses) and **Speed Settings** (speed multipliers, initial delay) if needed.
4. Click **Run**. The app moves the mouse, clicks, scrolls, and types according to the recording and your selected input source.
5. Press **Esc** to stop.

If the recording expects typed variables but none are provided, the app prompts you to use **Edit Data Input** or a CSV file on **Bulk Inputs**.

## Settings reference

### Run Options

| Setting | Description |
|---------|-------------|
| Smooth / Instant mouse | Curved movement vs teleport |
| Human-like / Instant typing | Randomized key timing vs immediate send |
| Click pause (ms) | Pause after moving to a target, before the click |
| Step pause (ms) | Pause after each target before the next step |
| Fixed pauses only | Uses your pause values; ignores elapsed time between recorded steps |
| Recorded gaps | Replays time gaps captured during recording (including right-click hold delays) |

### Speed Settings

| Setting | Description |
|---------|-------------|
| Run speed | Multiplier for recorded gap timing when **Recorded gaps** is enabled |
| Typing speed | Multiplier for per-key delay during human-like typing |
| Move speed | Multiplier for smooth mouse travel time (default: 10) |
| Initial delay (ms) | Wait before the first action |

### Data input file format

Saved under `saved-inputs/` as `*.txt`:

```ini
playback_speed=1.0
typing_speed=1.0
move_speed=10
initial_delay=1000
click_pause_ms=150
segment_pause_ms=200
use_recorded_timing=0
smooth_mouse=1
human_typing=1
description=Optional tooltip text for the list row
Alice
100
East
```

Variable rows can use optional note labels (`name:Alice` types `Alice`). Comma in a value: escape with backslash (`I\, LEE` types `I, LEE`).

## CSV batch format

Each row runs one full pass through the selected recording. Row 1 is a header with column labels for your notes; data starts on row 2.

```csv
row,name,qty,region
1,Alice,100,East
2,Bob,250,West
```

Single variable column:

```csv
value
hello
world
```

Rules:

- Row 1 is the header (not typed during Run); column 1 names the row label column, columns 2+ name variable-1, variable-2, ...
- Data rows: column 1 is the row label (status display); columns 2+ are the values typed during Run
- Escape a comma inside a value with backslash: `Smith\, Jones` types `Smith, Jones` (use `\\` for a literal `\`)
- Lines starting with `#` and blank lines are ignored
- **Config** (Bulk Inputs tab) sets run mode: **Ask to run next line** shows a progress table with all variable columns; before each row you can Run, Skip, or Run all remaining. **Run all rows automatically** skips prompts.
- **Esc** stops the whole batch; completed rows stay completed
- Use **Edit CSV** on the Bulk Inputs tab for table editing with automatic comma escaping on save

## Recording file format

Recordings are UTF-8 log files in `recordings/` (default prefix `di-`). They store pipe-delimited events for clicks, scrolls, keys, metadata, and manual delays. Coordinates prefer window percentage positions so replay survives window resize when possible. Optional header lines include `# description:`, `# playback_offset_x` / `# playback_offset_y`, and `# playback_reference_client_w` / `# playback_reference_client_h` (set from **Edit Log → Global Adjust**).

You can inspect or edit a log with **Edit Log** on the Recordings tab (Events, **Global Adjust**, and Raw log tabs).

## Does the exe need AutoHotkey installed?

**No.** If you use `DataEntryAutonoma.exe`, you do **not** need AutoHotkey installed on that computer.

| What you run | AutoHotkey required? | Notes |
|--------------|----------------------|-------|
| **`DataEntryAutonoma.exe`** | **No** | Standalone app. The AutoHotkey runtime is bundled inside the exe when it is compiled. Works on a clean Windows PC. |
| **`dataEntryAutonoma.ahk`** (source script) | **Yes** | For development only. Requires [AutoHotkey v2](https://www.autohotkey.com/) installed. |

When you build the exe with `compile.ps1`, Ahk2Exe packages the script and interpreter into one file. End users only need Windows 10 or 11 and the exe (plus optional `assets\`, `recordings\`, `saved-inputs\`, and `csv-batches\` folders).

**Quick test on a PC without AutoHotkey:** copy `DataEntryAutonoma.exe` to the machine, double-click it, and the main window should open. No install step for AutoHotkey is involved.

## Requirements

| Use case | Requirement |
|----------|-------------|
| Easiest install | Windows 10 or 11, run the [Install wizard](#install-wizard-optional) |
| End users | Windows 10 or 11, `DataEntryAutonoma.exe` ([Installation Path 1](#path-1-end-user-standalone-exe-recommended)) |
| Developers | Windows 10 or 11, [AutoHotkey v2](https://www.autohotkey.com/) ([Installation Path 2](#path-2-developer-run-the-ahk-script)) |
| Building the exe | AutoHotkey v2 with Ahk2Exe ([Installation Path 3](#path-3-build-the-standalone-exe-optional)) |

See [Installation](#installation) for full step-by-step instructions.

## Version history

Release notes are in [CHANGELOG.md](CHANGELOG.md).

| Version | Highlights |
|---------|------------|
| **1.3.0** | Edit Hotkeys, hold/drag path replay + hold speed, Save Recording labels, label sync (blue + tooltip), double-click list to edit, reverse-from-pause |
| **1.2.0** | Edit Log Global Adjust tab, playback offset, screen rescale, target window picker, per-row window fields |
| **1.1.2** | Edit Data Input and CSV editor UX, Create CSV button, default move speed 10, release exe validation |
| **1.1.1** | Install wizard auto-download and layout fixes, publishRelease script, source-vs-release guidance |
| **1.1.0** | CSV table editor, Share/Import portable bundles (`.dea.zip`), five-tab layout with Speed Settings, list hover tooltips, Edit Data Input and Edit Recording Log improvements, default move speed 3 |
| **1.0.6** | Data input note labels, CSV header row, Edit Recording Log table, Run Options-only mouse/typing, install/uninstall wizard version display |
| **1.0.5** | Tab layout fixes, **i** help on all tabs, install wizard fixes, `VERSION` in release zip, CSV/data input run-source layout |
| **1.0.4** | Tab info (i) buttons on all tabs, updated CSV help text, layout fixes for recordings list and tab buttons |
| **1.0.3** | Bulk Inputs tab, data input vs CSV run source, mouse hold/drag + hotkey recording fixes, all CSV variables in batch UI |
| **1.0.2** | CSV Config with ask next line, batch progress table, uninstall wizard in release zip |
| **1.0.1** | Install wizard upgrades existing installs in place; version shown in app title |
| **1.0.0** | Initial release: Record/Run, data inputs, CSV batch, install wizard, standalone exe |

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
  VERSION                 # Current version (read by packageRelease.ps1; sync with C.appVersion)
  packageRelease.ps1      # Build release zip from dist\DataEntryAutonoma.exe
  packageRelease.bat      # Shortcut for packageRelease.ps1
  compile.ps1             # Build standalone exe
  build.bat               # Build shortcut
  BUILD.md                # Detailed build and distribution guide
  assets/                 # App icon (SVG and ICO)
  recordings/             # Session logs (di-*.log)
  saved-inputs/           # Data input files (*.txt)
  csv-batches/            # Saved CSV bulk input files (*.csv)
  apply-state.ini         # Last selected recording, data input, CSV (auto-created)
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
| **Caps Lock** (hold) | Record manual delay | N/A |
| **Left-click** (hold or drag) | Record mouse hold/drag (saved on release) | Replays button down, drag or wait, button up |
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
