# Building DataEntryAutonoma.exe

**Data Entry Autonoma** — record input once, replay with presets or CSV batches.

## Standalone exe (no AutoHotkey on target PCs)

`DataEntryAutonoma.exe` is a **standalone** Windows application. **End users do not install AutoHotkey.**

During compile, Ahk2Exe embeds the AutoHotkey v2 interpreter into the exe. The target PC only needs Windows and the files you ship (exe, optional icon asset, data folders).

| Machine | AutoHotkey needed? |
|---------|-------------------|
| PC where you **build** the exe | Yes (v2 + Ahk2Exe) |
| PC where you **run** `DataEntryAutonoma.exe` | **No** |

Ship `DataEntryAutonoma.exe` plus the data folders below (and `assets\dataEntryAutonoma.ico` for tray/window icons).

## Prerequisites (build machine only)

1. [AutoHotkey v2](https://www.autohotkey.com/) installed (includes Ahk2Exe).
2. Default paths expected by `compile.ps1`:
   - `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`
   - `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`

If your install paths differ, edit the constants at the top of `compile.ps1`.

## Build

From the project root:

```powershell
.\compile.ps1
```

Or double-click / run:

```bat
build.bat
```

**Output:** `dist\DataEntryAutonoma.exe`

### Exact compile command

```bat
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "dataEntryAutonoma.ahk" /out "dist\DataEntryAutonoma.exe" /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
```

## Distribute to end users

Copy this layout (folders can start empty; the app creates them on first run if missing):

```
DataEntryAutonoma/
  DataEntryAutonoma.exe
  assets/
    dataEntryAutonoma.ico   ← optional but recommended for tray/taskbar icons
  recordings/               ← recording logs (di-*.log)
  saved-inputs/             ← input presets (*.txt)
  csv-batches/              ← saved CSV bulk input files (*.csv)
  apply-state.ini           ← optional; created automatically for last selections
  VERSION                   ← optional; copied by install wizard when present
  runUninstallWizard.bat    ← optional; copied by install wizard for removal
  runUninstallWizard.ps1
```

- Paths are relative to the **exe directory** (`A_ScriptDir` when compiled).
- Saved CSV bulk files live in `csv-batches\` (created on first run if missing).
- Entry script: `dataEntryAutonoma.ahk`.

## Development vs compiled

| Item | Script (`.ahk`) | Compiled (`.exe`) |
|------|-----------------|-------------------|
| `recordings\` | next to script | next to exe |
| `saved-inputs\` | next to script | next to exe |
| `csv-batches\` | next to script | next to exe |
| `apply-state.ini` | next to script | next to exe |

No source changes are required for exe compatibility; `dataEntryAutonoma.ahk` already uses `A_ScriptDir` for all local data paths.
## Release package (maintainers)

After a successful build, create the distributable zip and folder mirror:

```powershell
.\packageRelease.ps1
```

Or double-click / run:

```bat
packageRelease.bat
```

**Requires:** `dist\DataEntryAutonoma.exe` (run `.\compile.ps1` first if missing).

**Output:**

- `release\DataEntryAutonoma-v<VERSION>-win64.zip` (for example `DataEntryAutonoma-v1.3.0-win64.zip`)
- `release\DataEntryAutonoma-v<VERSION>-win64\` (same layout for inspection)

**Version sync (keep these aligned on every release):**

| File | Field |
|------|--------|
| `VERSION` | Plain text, for example `1.3.0` |
| `dataEntryAutonoma.ahk` | `C.appVersion` |
| `CHANGELOG.md` | New release section |
| `README.md` | Download zip name and version history table |

Version is read from the `VERSION` file at the project root (keep in sync with `C.appVersion` in `dataEntryAutonoma.ahk`).

The package includes `DataEntryAutonoma.exe`, `assets\dataEntryAutonoma.ico`, empty `recordings\`, `saved-inputs\`, and `csv-batches\`, `LICENSE`, `README.md`, `CHANGELOG.md`, `VERSION`, and `runInstallWizard.bat` / `runInstallWizard.ps1`. Uninstall wizard scripts are included when present. Publish the zip to [GitHub Releases](https://github.com/Jayrr-Dev/DataEntryAutonoma/releases).

The `release\` folder is build output and is listed in `.gitignore`.
