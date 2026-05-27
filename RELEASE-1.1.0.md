# Release checklist: Data Entry Autonoma v1.1.0

Use this list before publishing `DataEntryAutonoma-v1.1.0-win64.zip`.

## Pre-build (version sync)

- [ ] `VERSION` = `1.1.0`
- [ ] `dataEntryAutonoma.ahk`: header comment and `C.appVersion`
- [ ] `runInstallWizard.ps1` / `runUninstallWizard.ps1`: `APP_VERSION_FALLBACK`
- [ ] `packageRelease.ps1`: fallback `VERSION`
- [ ] `CHANGELOG.md`, `README.md`, `BUILD.md` updated

## Build and package (manual)

- [ ] `.\compile.ps1` succeeds → `dist\DataEntryAutonoma.exe`
- [ ] `.\packageRelease.ps1` succeeds → `release\DataEntryAutonoma-v1.1.0-win64.zip`
- [ ] Zip contains exe, assets, empty data folders, wizards, LICENSE, README, CHANGELOG, VERSION

## Smoke test (standalone exe)

- [ ] App title shows `Data Entry Autonoma v1.1.0`
- [ ] Record → Esc → save; Run with preset works
- [ ] **Import** / **Share** buttons visible on title row
- [ ] Share creates folder or `.dea.zip`; Import restores recording + preset or CSV
- [ ] CSV **Edit CSV** opens table editor (inline edit, add/delete rows/columns)
- [ ] Hover tooltips on recordings and data input lists
- [ ] Tab **i** help opens for Recordings, Data Inputs, Bulk Inputs, Recording events
- [ ] Edit Data Input saves without duplicating preset files
- [ ] Edit Log row labels persist after save

## Install / upgrade wizard

- [ ] Fresh install: welcome shows v1.1.0 tips (CSV editor, Share/Import)
- [ ] Upgrade from v1.0.6: shows from/to version; data folders preserved
- [ ] Setup complete references CSV editor and Share/Import
- [ ] Uninstall wizard shows installed version

## GitHub release

- [ ] Tag `v1.1.0`
- [ ] Upload `DataEntryAutonoma-v1.1.0-win64.zip`
- [ ] Release notes from `CHANGELOG.md` [1.1.0] section
