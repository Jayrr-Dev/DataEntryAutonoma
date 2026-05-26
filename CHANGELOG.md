# Changelog

All notable changes to **Data Entry Autonoma** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-05-26

### Added

- Shared tab layout helpers (`AddManageTabSectionLabel`, `BuildManageTabListOptions`) following AutoHotkey Tab control positioning rules

### Changed

- Recordings, presets, CSV, and Run Options tabs use consistent full-width list layout anchored with `Section` + `xs` (never `xm` inside tabs)

### Fixed

- Recordings ListView disappearing, shifting right, or showing empty after tab header and info button were added
- Recordings **Variable count** column width and tab button row clipping
- Run Options info button placement beside the label text

## [1.0.4] - 2026-05-26

### Added

- Info (**i**) buttons on every tab: Recordings, Input Presets, CSV Bulk Inputs, and Run Options

### Changed

- CSV Bulk Inputs help text rewritten (format, saved files, Config, Browse, and batch rules)
- Recordings and Run Options tabs include section headers for help placement
- Dynamic tab list heights adjusted for new section headers
- Recordings list column widths fixed so **Variable count** is not truncated; tab button rows fit without clipping

## [1.0.3] - 2026-05-26

### Added

- **CSV Bulk Inputs** tab: manage saved CSV files in `csv-batches\` with **Edit CSV**, **Rename**, **Delete**, **Browse**, and **Refresh**
- Import prompt when browsing an external CSV (copy into `csv-batches\` for editing later)
- Run input source radios: choose **Input preset** or **CSV bulk inputs** (mutually exclusive)
- CSV batch **Config** run mode radios: **Ask to run next line before each row** or **Run all rows automatically**
- Hotkey recording feedback beside the cursor (`Hotkey: Ctrl + c`) when a shortcut is saved
- CSV batch progress table and row prompt show **all** variable columns (not capped at five)

### Changed

- Mouse hold/drag while recording passes through to apps (Excel selection works normally); quick clicks stay clicks, hold or drag saves on release (no 2-second wait)
- Ctrl/Shift/Alt shortcuts work in target apps during recording and replay correctly
- **Config** button moved next to **Use CSV bulk inputs for Run** on the CSV tab
- Taller recordings list; CSV tab layout height fixes so bottom buttons are not clipped
- Install wizard and release zip create `csv-batches\` alongside `recordings\` and `saved-inputs\`

### Fixed

- Mouse hold/drag replay used wrong end coordinates from the log parser (drag direction)
- CSV batch variable display limited to five columns in progress table and row prompt

## [1.0.2] - 2026-05-26

### Added

- CSV batch **Config** button on the Input Presets tab with **Ask to run next line** option (persisted in `apply-state.ini`)
- Step-by-step CSV batch mode: always-on-top progress table (Row, Var1–Var5, Status) and non-modal per-row prompt (Run this row, Skip, Run all remaining)
- Graphical uninstall wizard (`runUninstallWizard.ps1` / `.bat`) included in release packages when present

### Changed

- CSV batch help text mentions Config and ask-next-line mode

## [1.0.1] - 2026-05-26

### Added

- Version history (`CHANGELOG.md`) and `VERSION` file for releases
- App version shown in the main window title (`Data Entry Autonoma v1.0.1`)

### Changed

- Install wizard upgrades existing installations in place: overwrites the exe, assets, LICENSE, README, and wizard scripts while preserving `recordings\` and `saved-inputs\` user data
- Install wizard shows **Upgrading existing installation** when reinstalling to a folder that already contains `DataEntryAutonoma.exe`

## [1.0.0] - 2026-05-26

### Added

- Record and Run workflow: capture mouse clicks, scrolls, and keyboard input once, then replay with presets or CSV batches
- Input presets with configurable mouse movement, typing speed, pauses, and variable text values
- CSV batch mode: run the same recording once per row with different variable values
- Shift-hold delays during recording for manual pauses between steps
- Graphical install wizard (`runInstallWizard.ps1`) for end-user setup with Desktop and Start Menu shortcuts
- Standalone `DataEntryAutonoma.exe` (no AutoHotkey required on target PCs)
- MIT license with required attribution

[1.0.5]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Jayrr-Dev/DataEntryAutonoma/releases/tag/v1.0.0
