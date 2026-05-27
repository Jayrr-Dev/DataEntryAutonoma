# Release checklist: Data Entry Autonoma v1.2.0

Use this list before publishing `DataEntryAutonoma-v1.2.0-win64.zip`.

## Pre-build (version sync)

- [ ] `VERSION` = `1.2.0`
- [ ] `dataEntryAutonoma.ahk`: header comment and `C.appVersion`
- [ ] `runInstallWizard.ps1` / `runUninstallWizard.ps1`: `APP_VERSION_FALLBACK`
- [ ] `packageRelease.ps1`: fallback `VERSION`
- [ ] `CHANGELOG.md`, `README.md`, `BUILD.md` updated

## Build and package

- [ ] `.\publishRelease.ps1` succeeds (compile + package validation + GitHub upload)
- [ ] Zip exe contains string `1.2.0` and not `1.0.5` / `Input Presets`
- [ ] Zip exe contains `Global Adjust` (sanity check for this release)

## Smoke test (standalone exe)

- [ ] App title shows `Data Entry Autonoma v1.2.0`
- [ ] Edit Log → **Global Adjust** tab: offset, Screen w/h, target title dropdown + ↻
- [ ] Edit Log → Events: per-row Window title / Exe on click rows
- [ ] Apply target window + Save persists window metadata

## GitHub release

- [ ] Tag `v1.2.0`
- [ ] Asset `DataEntryAutonoma-v1.2.0-win64.zip` attached
- [ ] Release notes from `CHANGELOG.md` [1.2.0] section
