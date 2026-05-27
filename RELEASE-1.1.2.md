# Release checklist: Data Entry Autonoma v1.1.2

Use this list before publishing `DataEntryAutonoma-v1.1.2-win64.zip`.

## Pre-build (version sync)

- [ ] `VERSION` = `1.1.2`
- [ ] `dataEntryAutonoma.ahk`: header comment and `C.appVersion`
- [ ] `runInstallWizard.ps1` / `runUninstallWizard.ps1`: `APP_VERSION_FALLBACK`
- [ ] `packageRelease.ps1`: fallback `VERSION`
- [ ] `CHANGELOG.md`, `README.md`, `BUILD.md` updated

## Build and package

- [ ] `.\publishRelease.ps1` succeeds (compile + package validation + GitHub upload)
- [ ] Compile output shows ~1465+ KB (not stale ~1382 KB v1.0.5 build)
- [ ] Zip exe contains string `1.1.2` and not `1.0.5` / `Input Presets`

## Smoke test (standalone exe)

- [ ] App title shows `Data Entry Autonoma v1.1.2`
- [ ] Speed Settings default move speed is 10
- [ ] Edit Data Input: inline edit, auto comma escape, no Selected row panel
- [ ] Bulk Inputs: **Create CSV** and **Edit** buttons; CSV editor 720px wide

## GitHub release

- [ ] Tag `v1.1.2`
- [ ] Asset `DataEntryAutonoma-v1.1.2-win64.zip` attached
- [ ] Release notes from `CHANGELOG.md` [1.1.2] section
