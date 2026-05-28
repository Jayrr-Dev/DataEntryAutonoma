# Release checklist: Data Entry Autonoma v1.3.0

Use this list before publishing `DataEntryAutonoma-v1.3.0-win64.zip`.

## Pre-build (version sync)

- [ ] `VERSION` = `1.3.0`
- [ ] `dataEntryAutonoma.ahk`: header comment and `C.appVersion`
- [ ] `runInstallWizard.ps1` / `runUninstallWizard.ps1`: `APP_VERSION_FALLBACK`
- [ ] `packageRelease.ps1`: fallback `VERSION`
- [ ] `CHANGELOG.md`, `README.md`, `BUILD.md` updated

## Build and package

- [ ] `.\compile.ps1` succeeds
- [ ] `.\packageRelease.ps1` succeeds (compile + package validation)
- [ ] Zip exe contains string `1.3.0` and not `1.2.0` / `Input Presets`
- [ ] Zip exe contains `Edit Hotkeys` and `Hold speed` (sanity check for this release)

## Smoke test (standalone exe)

### Recording & hotkeys

- [ ] App title shows `Data Entry Autonoma v1.3.0`
- [ ] **PgUp** starts recording; **PgUp** again opens Save Recording dialog
- [ ] **Esc** saves while recording (same dialog)
- [ ] Save dialog: variable label grid when recording used a/b/c keys; default name from window title
- [ ] Hold/drag circle replays as a path (not a dot or straight line)

### Edit Hotkeys

- [ ] Run Options → **Edit Hotkeys** shows Start/save (PgUp), Save (Esc), playback keys
- [ ] Change a key → reload script → binding persists
- [ ] **Reset defaults** restores PgUp / Esc / PgDn / arrows

### Playback

- [ ] **Hold speed** 2.0 replays hold/drag faster than 1.0
- [ ] **PgDn** pause → **Left** rewinds from current step (not from start)
- [ ] Assignment tooltip shows merged label (e.g. custom label or Var1)

### Label sync

- [ ] Edit Data Input: empty Label + selected recording → **blue** text
- [ ] Hover blue label → `Sync from {recording name}` (Windows tooltip timing)
- [ ] Save without editing label → stored file still has empty label (sync is display-only)
- [ ] Edit CSV row 1: same blue + tooltip for empty variable headers

### Lists & editors

- [ ] Double-click **Name** on Recordings → Edit Log
- [ ] Double-click **Name** on Data Inputs → Edit Data Input
- [ ] Double-click **Name** on Bulk Inputs → Edit CSV

### Regression (from v1.2.0)

- [ ] Edit Log → **Global Adjust**: offset, Screen w/h, target title picker + ↻
- [ ] CSV batch Run with ask-next-line progress table
- [ ] Share / Import bundle still works

## GitHub release

- [ ] Tag `v1.3.0`
- [ ] Asset `DataEntryAutonoma-v1.3.0-win64.zip` attached
- [ ] Release notes from `CHANGELOG.md` [1.3.0] section
