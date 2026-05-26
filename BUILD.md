# Building InputRelay.exe

**Input Relay** — record input once, replay with presets or CSV batches.

End users do **not** need AutoHotkey installed. Ship `InputRelay.exe` plus the data folders below.

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

**Output:** `dist\InputRelay.exe`

### Exact compile command

```bat
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "relayInput.ahk" /out "dist\InputRelay.exe" /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
```

## Distribute to end users

Copy this layout (folders can start empty; the app creates them on first run if missing):

```
InputRelay/
  InputRelay.exe
  recordings/          ← recording logs (di-*.log)
  saved-inputs/        ← input presets (*.txt)
  apply-state.ini      ← optional; created automatically for last selections
```

- Paths are relative to the **exe directory** (`A_ScriptDir` when compiled).
- CSV batch files can live anywhere; users pick them via Browse.
- Entry script: `relayInput.ahk`.

## Development vs compiled

| Item | Script (`.ahk`) | Compiled (`.exe`) |
|------|-----------------|-------------------|
| `recordings\` | next to script | next to exe |
| `saved-inputs\` | next to script | next to exe |
| `apply-state.ini` | next to script | next to exe |

No source changes are required for exe compatibility; `relayInput.ahk` already uses `A_ScriptDir` for all local data paths.
