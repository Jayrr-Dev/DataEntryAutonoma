# Release checklist: Data Entry Autonoma v1.1.1

Use this list before publishing `DataEntryAutonoma-v1.1.1-win64.zip`.

## Pre-build (version sync)

- [ ] `VERSION` = `1.1.1`
- [ ] `dataEntryAutonoma.ahk`: header comment and `C.appVersion`
- [ ] `runInstallWizard.ps1` / `runUninstallWizard.ps1`: `APP_VERSION_FALLBACK`
- [ ] `packageRelease.ps1`: fallback `VERSION`
- [ ] `CHANGELOG.md`, `README.md`, `BUILD.md` updated

## Build and package

- [ ] `.\publishRelease.ps1` succeeds (compile + package + GitHub upload)
- [ ] Or manually: `.\compile.ps1` then `.\packageRelease.ps1`
- [ ] Zip contains exe, assets, empty data folders, wizards, LICENSE, README, CHANGELOG, VERSION

## Smoke test (standalone exe)

- [ ] App title shows `Data Entry Autonoma v1.1.1`
- [ ] Record → Esc → save; Run with preset works
- [ ] **Import** / **Share** buttons visible on title row
- [ ] Share creates folder or `.dea.zip`; Import restores recording + preset or CSV

## Install wizard

- [ ] Fresh install from release zip: welcome auto-downloads or uses bundled exe
- [ ] Welcome text is fully visible (no clipping)
- [ ] Retry / Open releases / Browse fallbacks work when download fails
- [ ] Clear message when GitHub source zip is used instead of release zip
- [ ] Uninstall wizard shows installed version v1.1.1

## GitHub release

- [ ] Tag `v1.1.1`
- [ ] Asset `DataEntryAutonoma-v1.1.1-win64.zip` attached
- [ ] Release notes from `CHANGELOG.md` [1.1.1] section
